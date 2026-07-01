#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "dpi.h"

static dpiErrorInfo g_last_error;
static dpiContext *g_context = NULL;
static int g_has_error = 0;

typedef struct {
    dpiConn *conn;
    dpiStmt *stmt;

    dpiVar *vars[64];
    uint32_t var_count;

    dpiLob *lobs[64];
    uint32_t lob_count;
} oracle_stmt;

static void oracle_release_vars(oracle_stmt *stmt)
{
    if (!stmt)
        return;

    for (uint32_t i = 0; i < stmt->var_count; i++)
    {
        if (stmt->vars[i])
            dpiVar_release(stmt->vars[i]);
    }

    stmt->var_count = 0;
}

static void oracle_capture_error(const dpiErrorInfo *error)
{
    if (error == NULL)
        return;

    memset(&g_last_error, 0, sizeof(g_last_error));

    g_last_error.code = error->code;
    g_last_error.message = error->message;
    g_last_error.messageLength = error->messageLength;
    g_last_error.fnName = error->fnName;
    g_last_error.isRecoverable = error->isRecoverable;
    g_last_error.isWarning = error->isWarning;

    /*
     * ODPI-C sometimes leaves code as 0 for initialization
     * errors (for example DPI-1047).
     */
    if (g_last_error.code == 0 && error->message != NULL)
    {
        int parsed;

        if (sscanf(error->message, "DPI-%d:", &parsed) == 1)
        {
            g_last_error.code = parsed;
        }
    }

    g_has_error = 1;
}

static void oracle_capture_last_error(void)
{
    if (g_context == NULL)
        return;

    dpiErrorInfo error;
    memset(&error, 0, sizeof(error));

    dpiContext_getError(
        g_context,
        &error
    );

    oracle_capture_error(&error);
}

static int oracle_init_context(void)
{
    if (g_context != NULL)
        return 0;

    dpiErrorInfo error;

    if (dpiContext_create(
            DPI_MAJOR_VERSION,
            DPI_MINOR_VERSION,
            &g_context,
            &error) != DPI_SUCCESS)
    {
        oracle_capture_error(&error);
        return -1;
    }

    return 0;
}

int32_t get_error_code(void)
{
    if (!g_has_error)
        return 0;

    return (int32_t) g_last_error.code;
}

const char *get_error_message(void)
{
    if (!g_has_error)
        return "";

    return g_last_error.message;
}

dpiQueryInfo *oracle_query_info(oracle_stmt *stmt, int32_t column)
{
    dpiQueryInfo *info = malloc(sizeof(dpiQueryInfo));

    if (!info)
        return NULL;

    if (dpiStmt_getQueryInfo(
            stmt->stmt,
            column + 1,
            info) < 0)
    {
        free(info);
        oracle_capture_last_error();
        return NULL;
    }

    return info;
}

void oracle_query_info_free(dpiQueryInfo *info)
{
    free(info);
}

int32_t oracle_query_info_type(dpiQueryInfo *info)
{
    return info->typeInfo.oracleTypeNum;
}

char *oracle_query_info_name(dpiQueryInfo *info)
{
    char *result = malloc(info->nameLength + 1);

    if (!result)
        return NULL;

    memcpy(result, info->name, info->nameLength);
    result[info->nameLength] = '\0';

    return result;
}

int32_t oracle_query_info_nullable(dpiQueryInfo *info)
{
    return info->nullOk;
}

uint32_t oracle_query_info_size(dpiQueryInfo *info)
{
    return info->typeInfo.sizeInChars;
}

int32_t oracle_data_is_null(dpiData *data)
{
    if (!data)
        return 1;

    return data->isNull;
}

int64_t oracle_data_int64(dpiData *data)
{
    if (!data)
        return 0;

    return data->value.asInt64;
}

double oracle_data_double(dpiData *data)
{
    if (!data)
        return 0.0;

    return data->value.asDouble;
}

char *oracle_data_string(dpiData *data)
{
    if (!data)
        return NULL;

    dpiBytes *bytes = &data->value.asBytes;

    char *result = malloc(bytes->length + 1);

    if (!result)
        return NULL;

    memcpy(result, bytes->ptr, bytes->length);
    result[bytes->length] = '\0';

    return result;
}

void oracle_string_free(char *str)
{
    free(str);
}

int32_t oracle_bind_null(oracle_stmt *stmt, const char *name)
{
    dpiData data;
    memset(&data, 0, sizeof(data));

    data.isNull = 1;

    int rc = dpiStmt_bindValueByName(
        stmt->stmt,
        name,
        strlen(name),
        DPI_NATIVE_TYPE_BYTES,
        &data);

    if (rc < 0)
        oracle_capture_last_error();

    return rc;
}

int32_t oracle_bind_bool(oracle_stmt *stmt, const char *name, int value)
{
    dpiData data;
    memset(&data, 0, sizeof(data));

    dpiData_setBool(&data, value != 0);

    int rc = dpiStmt_bindValueByName(
        stmt->stmt,
        name,
        strlen(name),
        DPI_NATIVE_TYPE_BOOLEAN,
        &data);

    if (rc < 0)
        oracle_capture_last_error();

    return rc;
}

int32_t oracle_bind_string(oracle_stmt *stmt, const char *name, const char *value)
{
    dpiData data;
    memset(&data, 0, sizeof(data));

    dpiData_setBytes(&data, (char *) value, strlen(value));

    int rc = dpiStmt_bindValueByName(
        stmt->stmt,
        name,
        strlen(name),
        DPI_NATIVE_TYPE_BYTES,
        &data);

    if (rc < 0)
        oracle_capture_last_error();

    return rc;
}

int32_t oracle_bind_int64(oracle_stmt *stmt, const char *name, int64_t value)
{
    dpiData data;
    memset(&data, 0, sizeof(data));

    dpiData_setInt64(&data, value);

    int rc = dpiStmt_bindValueByName(
        stmt->stmt,
        name,
        strlen(name),
        DPI_NATIVE_TYPE_INT64,
        &data);

    if (rc < 0)
        oracle_capture_last_error();

    return rc;
}

int32_t oracle_bind_double(oracle_stmt *stmt, const char *name, double value)
{
    dpiData data;
    memset(&data, 0, sizeof(data));

    dpiData_setDouble(&data, value);

    int rc = dpiStmt_bindValueByName(
        stmt->stmt,
        name,
        strlen(name),
        DPI_NATIVE_TYPE_DOUBLE,
        &data);

    if (rc < 0)
        oracle_capture_last_error();

    return rc;
}

int32_t oracle_bind_clob(oracle_stmt *stmt, const char *name, const char *value)
{
    dpiVar *var = NULL;
    dpiData *data = NULL;
    dpiLob *lob = NULL;

    if (dpiConn_newVar(
            stmt->conn,
            DPI_ORACLE_TYPE_CLOB,
            DPI_NATIVE_TYPE_LOB,
            1,
            0,
            0,
            0,
            NULL,
            &var,
            &data) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    if (dpiStmt_bindByName(
            stmt->stmt,
            name,
            (uint32_t) strlen(name),
            var) < 0)
    {
        oracle_capture_last_error();
        dpiVar_release(var);
        return -1;
    }

    if (dpiConn_newTempLob(
            stmt->conn,
            DPI_ORACLE_TYPE_CLOB,
            &lob) < 0)
    {
        oracle_capture_last_error();
        dpiVar_release(var);
        return -1;
    }

    if (dpiLob_writeBytes(
            lob,
            1,
            value,
            (uint64_t) strlen(value)) < 0)
    {
        oracle_capture_last_error();
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    if (dpiVar_setFromLob(
            var,
            0,
            lob) < 0)
    {
        oracle_capture_last_error();
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    if (stmt->var_count >= 64 ||
        stmt->lob_count >= 64)
    {
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    stmt->vars[stmt->var_count++] = var;
    stmt->lobs[stmt->lob_count++] = lob;

    return 0;
}

int32_t oracle_bind_blob(oracle_stmt *stmt, const char *name, const char *value)
{
    dpiVar *var = NULL;
    dpiData *data = NULL;
    dpiLob *lob = NULL;

    if (dpiConn_newVar(
            stmt->conn,
            DPI_ORACLE_TYPE_BLOB,
            DPI_NATIVE_TYPE_LOB,
            1,
            0,
            0,
            0,
            NULL,
            &var,
            &data) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    if (dpiStmt_bindByName(
            stmt->stmt,
            name,
            (uint32_t) strlen(name),
            var) < 0)
    {
        oracle_capture_last_error();
        dpiVar_release(var);
        return -1;
    }

    if (dpiConn_newTempLob(
            stmt->conn,
            DPI_ORACLE_TYPE_BLOB,
            &lob) < 0)
    {
        oracle_capture_last_error();
        dpiVar_release(var);
        return -1;
    }

    if (dpiLob_writeBytes(
            lob,
            1,
            value,
            (uint64_t) strlen(value)) < 0)
    {
        oracle_capture_last_error();
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    if (dpiVar_setFromLob(
            var,
            0,
            lob) < 0)
    {
        oracle_capture_last_error();
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    if (stmt->var_count >= 64 ||
        stmt->lob_count >= 64)
    {
        dpiLob_release(lob);
        dpiVar_release(var);
        return -1;
    }

    stmt->vars[stmt->var_count++] = var;
    stmt->lobs[stmt->lob_count++] = lob;

    return 0;
}

oracle_stmt *oracle_prepare_stmt(dpiConn *conn, const char *sql)
{
    oracle_stmt *result = malloc(sizeof(oracle_stmt));

    if (!result)
        return NULL;

    memset(result, 0, sizeof(oracle_stmt));

    if (dpiConn_prepareStmt(
            conn,
            0,
            sql,
            strlen(sql),
            NULL,
            0,
            &result->stmt) < 0)
    {
        oracle_capture_last_error();
        free(result);
        return NULL;
    }

    result->conn = conn;

    return result;
}

void oracle_release_stmt(oracle_stmt *stmt)
{
    if (!stmt)
        return;

    oracle_release_vars(stmt);

    if (stmt->stmt)
        dpiStmt_release(stmt->stmt);

    free(stmt);
}

int32_t oracle_execute_stmt(oracle_stmt *stmt)
{
    uint32_t cols = 0;

    if (!stmt || !stmt->stmt)
        return -1;

    if (dpiStmt_execute(
            stmt->stmt,
            DPI_MODE_EXEC_DEFAULT,
            &cols) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    return 0;
}

int32_t oracle_fetch(oracle_stmt *stmt)
{
    int found;
    uint32_t row;

    if (dpiStmt_fetch(
            stmt->stmt,
            &found,
            &row) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    return found ? 1 : 0;
}

int32_t oracle_column_count(oracle_stmt *stmt)
{
    uint32_t count;

    if (dpiStmt_getNumQueryColumns(
            stmt->stmt,
            &count) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    return count;
}

char *oracle_column_name(oracle_stmt *stmt, int32_t column)
{
    dpiQueryInfo info;

    if (dpiStmt_getQueryInfo(
            stmt->stmt,
            column + 1,
            &info) < 0)
    {
        oracle_capture_last_error();
        return NULL;
    }

    char *result = malloc(info.nameLength + 1);

    memcpy(
        result,
        info.name,
        info.nameLength
    );
    result[info.nameLength] = '\0';

    return result;
}

int32_t oracle_column_type(oracle_stmt *stmt, int32_t column)
{
    dpiQueryInfo info;

    if (dpiStmt_getQueryInfo(
            stmt->stmt,
            column + 1,
            &info) < 0)
    {
        oracle_capture_last_error();
        return -1;
    }

    return info.typeInfo.oracleTypeNum;
}

void *oracle_column_value(oracle_stmt *stmt, int32_t column)
{
    dpiNativeTypeNum type;
    dpiData *data;

    if (dpiStmt_getQueryValue(
            stmt->stmt,
            column + 1,
            &type,
            &data) < 0)
    {
        oracle_capture_last_error();
        return NULL;
    }

    return data;
}

int32_t oracle_commit(dpiConn *conn)
{
    if (!conn)
        return -1;

    if (dpiConn_commit(conn) < 0) {
        oracle_capture_last_error();
        return -1;
    }

    return 0;
}

int32_t oracle_rollback(dpiConn *conn)
{
    if (!conn)
        return -1;

    if (dpiConn_rollback(conn) < 0) {
        oracle_capture_last_error();
        return -1;
    }

    return 0;
}

dpiLob *oracle_data_lob(dpiData *data)
{
    return data ? data->value.asLOB : NULL;
}

int64_t oracle_lob_size(dpiLob *lob)
{
    uint64_t size;

    if (!lob)
        return -1;

    if (dpiLob_getSize(lob, &size) < 0) {
        oracle_capture_last_error();
        return -1;
    }

    return size;
}

char *oracle_lob_read(dpiLob *lob, int64_t offset, int64_t length)
{
    char *buffer = malloc(length + 1);

    if (!buffer)
        return NULL;

    if (dpiLob_readBytes(
            lob,
            offset,
            length,
            buffer,
            NULL) < 0)
    {
        oracle_capture_last_error();
        free(buffer);
        return NULL;
    }

    buffer[length] = 0;

    return buffer;
}

void oracle_lob_release(dpiLob *lob)
{
    if (lob)
        dpiLob_release(lob);
}

void oracle_lob_free_buffer(char *buffer)
{
    free(buffer);
}

void* oracle_connect(const char* username, const char* password, const char* connect_string)
{
    if (oracle_init_context() != 0)
        return NULL;

    dpiConn *conn = NULL;

    dpiErrorInfo error;
    memset(&error, 0, sizeof(error));

    int rc = dpiConn_create(
        g_context,
        username,
        strlen(username),
        password,
        strlen(password),
        connect_string,
        strlen(connect_string),
        NULL,
        NULL,
        &conn
    );

    if (rc != DPI_SUCCESS)
    {
        oracle_capture_error(&error);
        return NULL;
    }

    return conn;
}

void oracle_disconnect(dpiConn *conn)
{
    if (conn)
        dpiConn_release(conn);
}
