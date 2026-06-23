#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "dpi.h"

dpiQueryInfo *oracle_query_info(dpiStmt *stmt, int32_t column)
{
    dpiQueryInfo *info;

    info = malloc(sizeof(dpiQueryInfo));

    if (!info)
        return NULL;

    if (dpiStmt_getQueryInfo(stmt, column + 1, info) < 0) {
        free(info);
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
    char *result;

    result = malloc(info->nameLength + 1);

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

    dpiBytes *bytes;
    char *result;

    bytes = &data->value.asBytes;

    result = malloc(bytes->length + 1);

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

int32_t oracle_bind_null(dpiStmt *stmt, const char *name)
{
    dpiData data;

    memset(&data, 0, sizeof(data));

    data.isNull = 1;

    return dpiStmt_bindValueByName(
        stmt,
        name,
        (uint32_t) strlen(name),
        DPI_NATIVE_TYPE_BYTES,
        &data);
}

int32_t oracle_bind_string(dpiStmt *stmt, const char *name, const char *value)
{
    dpiData data;

    memset(&data, 0, sizeof(data));

    dpiData_setBytes(
        &data,
        (char *) value,
        (uint32_t) strlen(value));

    return dpiStmt_bindValueByName(
        stmt,
        name,
        (uint32_t) strlen(name),
        DPI_NATIVE_TYPE_BYTES,
        &data);
}

int32_t oracle_bind_int64(dpiStmt *stmt, const char *name, int64_t value)
{
    dpiData data;

    memset(&data, 0, sizeof(data));

    dpiData_setInt64(
        &data,
        value);

    return dpiStmt_bindValueByName(
        stmt,
        name,
        (uint32_t) strlen(name),
        DPI_NATIVE_TYPE_INT64,
        &data);
}

int32_t oracle_bind_double(dpiStmt *stmt, const char *name, double value)
{
    dpiData data;

    memset(&data, 0, sizeof(data));

    dpiData_setDouble(
        &data,
        value);

    return dpiStmt_bindValueByName(
        stmt,
        name,
        (uint32_t) strlen(name),
        DPI_NATIVE_TYPE_DOUBLE,
        &data);
}

int32_t oracle_bind_bool(dpiStmt *stmt, const char *name, int32_t value)
{
    dpiData data;

    memset(&data, 0, sizeof(data));

    dpiData_setBool(
        &data,
        value != 0);

    return dpiStmt_bindValueByName(
        stmt,
        name,
        (uint32_t) strlen(name),
        DPI_NATIVE_TYPE_BOOLEAN,
        &data);
}

dpiStmt *oracle_prepare_stmt(dpiConn *conn, const char *sql)
{
    dpiStmt *stmt;

    if (dpiConn_prepareStmt(
            conn,
            0,
            sql,
            strlen(sql),
            NULL,
            0,
            &stmt) < 0)
        return NULL;

    return stmt;
}

void oracle_release_stmt(dpiStmt *stmt)
{
    if (stmt)
        dpiStmt_release(stmt);
}

int32_t oracle_execute_stmt(dpiStmt *stmt)
{
    uint32_t numQueryColumns;

    if (dpiStmt_execute(
            stmt,
            DPI_MODE_EXEC_DEFAULT,
            &numQueryColumns) < 0)
        return -1;

    return 0;
}

int32_t oracle_fetch(dpiStmt *stmt)
{
    int found;
    uint32_t bufferRowIndex;

    if (dpiStmt_fetch(
            stmt,
            &found,
            &bufferRowIndex) < 0)
        return -1;

    return found ? 1 : 0;
}

int32_t oracle_column_count(dpiStmt *stmt)
{
    uint32_t count;

    if (dpiStmt_getNumQueryColumns(
            stmt,
            &count) < 0)
        return -1;

    return (int32_t) count;
}

char *oracle_column_name(dpiStmt *stmt, int32_t column)
{
    dpiQueryInfo info;
    char *result;
    size_t len;

    if (dpiStmt_getQueryInfo(
            stmt,
            column + 1,
            &info) < 0)
        return NULL;

    len = info.nameLength;

    result = malloc(len + 1);

    if (!result)
        return NULL;

    memcpy(result, info.name, len);

    result[len] = '\0';

    return result;
}

int32_t oracle_column_type(dpiStmt *stmt, int32_t column)
{
    dpiQueryInfo info;

    if (dpiStmt_getQueryInfo(
            stmt,
            column + 1,
            &info) < 0)
        return -1;

    return info.typeInfo.oracleTypeNum;
}



void *oracle_column_value(dpiStmt *stmt, int32_t column)
{
    dpiNativeTypeNum nativeType;
    dpiData *data;

    if (dpiStmt_getQueryValue(
            stmt,
            column + 1,
            &nativeType,
            &data) < 0)
        return NULL;

    return data;
}

int32_t oracle_commit(dpiConn *conn)
{
    if (!conn)
        return -1;

    if (dpiConn_commit(conn) < 0)
        return -1;

    return 0;
}

int32_t oracle_rollback(dpiConn *conn)
{
    if (!conn)
        return -1;

    if (dpiConn_rollback(conn) < 0)
        return -1;

    return 0;
}

dpiLob *oracle_data_lob(dpiData *data)
{
    if (!data)
        return NULL;

    return data->value.asLOB;
}

int64_t oracle_lob_size(dpiLob *lob)
{
    uint64_t size;

    if (!lob)
        return -1;

    if (dpiLob_getSize(lob, &size) < 0)
        return -1;

    return (int64_t) size;
}

char *oracle_lob_read(dpiLob *lob, int64_t offset, int64_t length)
{
    char *buffer;

    buffer = malloc(length + 1);

    if (!buffer)
        return NULL;


    if (dpiLob_readBytes(
            lob,
            offset,
            length,
            buffer,
            NULL) < 0)
    {
        free(buffer);
        return NULL;
    }


    buffer[length] = 0;

    return buffer;
}

char *oracle_clob_read(dpiLob *lob)
{
    uint64_t size;
    char *buffer;


    if (dpiLob_getSize(lob, &size) < 0)
        return NULL;


    buffer = malloc(size + 1);

    if (!buffer)
        return NULL;


    if (dpiLob_readBytes(
            lob,
            1,
            size,
            buffer,
            NULL) < 0)
    {
        free(buffer);
        return NULL;
    }


    buffer[size] = 0;

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
