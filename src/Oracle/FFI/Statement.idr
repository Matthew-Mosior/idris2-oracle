module Oracle.FFI.Statement

%default total

||| Prepare a SQL statement.
|||
||| Parameters:
|||
||| * Oracle connection handle
||| * SQL text
|||
||| Returns:
|||
||| * Raw dpiStmt pointer
||| * NULL on failure
|||
export %foreign "C:oracle_prepare_stmt"
prim__prepareStmt : AnyPtr -> String -> PrimIO AnyPtr

||| Release a previously prepared statement.
|||
||| This ultimately calls dpiStmt_release().
|||
export %foreign "C:oracle_release_stmt"
prim__releaseStmt : AnyPtr -> PrimIO ()

||| Execute a prepared statement.
|||
||| Returns:
||| * 0 on success.
||| * non-zero on failure.
|||
export %foreign "C:oracle_execute_stmt"
prim__executeStmt : AnyPtr -> PrimIO Int32

||| Fetch the next row from a query result.
|||
||| Returns:
||| * 1 if a row was fetched.
||| * 0 if no rows remain.
||| * negative value on error.
|||
export %foreign "C:oracle_fetch"
prim__fetch : AnyPtr -> PrimIO Int32

||| Retrieve the number of columns in the statement result set.
|||
export %foreign "C:oracle_column_count"
prim__columnCount : AnyPtr -> PrimIO Int32

||| Retrieve the name of a column.
|||
||| Column indexes are zero-based.
|||
export %foreign "C:oracle_column_name"
prim__columnName : AnyPtr -> Int32 -> PrimIO String

||| Retrieve the Oracle native type number
||| for a column.
|||
||| Returned values typically correspond to DPI_ORACLE_TYPE_* constants.
|||
export %foreign "C:oracle_column_type"
prim__columnType : AnyPtr -> Int32 -> PrimIO Int32

||| Retrieve the current row value for a
||| column.
|||
||| This interface is not sufficient for a production-quality Oracle driver.
||| Oracle values should be marshalled through type-specific accessors instead.
|||
export %foreign "C:oracle_column_value"
prim__columnValue : AnyPtr -> Int32 -> PrimIO AnyPtr
