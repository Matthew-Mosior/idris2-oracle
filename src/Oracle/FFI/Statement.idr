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
export %foreign "C:oracle_prepare_stmt,oracle-idris"
prim__prepareStmt : AnyPtr -> String -> PrimIO AnyPtr

||| Release a previously prepared statement.
|||
||| This ultimately calls dpiStmt_release().
|||
export %foreign "C:oracle_release_stmt,oracle-idris"
prim__releaseStmt : AnyPtr -> PrimIO ()

||| Execute a prepared statement.
|||
||| Returns:
||| * 0 on success.
||| * non-zero on failure.
|||
export %foreign "C:oracle_execute_stmt,oracle-idris"
prim__executeStmt : AnyPtr -> PrimIO Int32

||| Fetch the next row from a query result.
|||
||| Returns:
||| * 1 if a row was fetched.
||| * 0 if no rows remain.
||| * negative value on error.
|||
export %foreign "C:oracle_fetch,oracle-idris"
prim__fetch : AnyPtr -> PrimIO Int32

||| Retrieve the number of columns in the statement result set.
|||
export %foreign "C:oracle_column_count,oracle-idris"
prim__columnCount : AnyPtr -> PrimIO Int32

||| Retrieve the current row value for a column.
|||
||| This interface is not sufficient for a production-quality Oracle driver.
||| Oracle values should be marshalled through type-specific accessors instead.
|||
export %foreign "C:oracle_column_value,oracle-idris"
prim__columnValue : AnyPtr -> Int32 -> PrimIO AnyPtr
