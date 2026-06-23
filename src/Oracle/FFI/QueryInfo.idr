module Oracle.FFI.QueryInfo

||| Retrieve metadata for a query column.
|||
||| Parameters:
||| - Statement handle.
||| - Zero-based column index.
|||
||| Returns:
||| - Pointer to an allocated dpiQueryInfo structure.
||| - NULL on failure.
|||
export %foreign "C:oracle_query_info"
prim__queryInfo : AnyPtr -> Int32 -> PrimIO AnyPtr

||| Frees query column metadata.
|||
export %foreign "C:oracle_query_info_free"
prim__queryInfoFree : AnyPtr -> PrimIO ()

||| Retrieve the Oracle type number for a column.
|||
export %foreign "C:oracle_query_info_type"
prim__queryInfoType : AnyPtr -> PrimIO Int32

||| Retrieve the column name from a dpiQueryInfo structure.
|||
||| Returns the Oracle column name exactly as reported by ODPI-C.
|||
export %foreign "C:oracle_query_info_name"
prim__queryInfoName : AnyPtr -> PrimIO String

||| Returns whether the column accepts NULL values.
|||
||| Result:
||| - 1 = nullable
||| - 0 = not nullable
|||
export %foreign "C:oracle_query_info_nullable"
prim__queryInfoNullable : AnyPtr -> PrimIO Int32

||| Retrieve the declared size of the column.
|||
||| For character columns this typically corresponds to the maximum number of characters.
|||
export %foreign "C:oracle_query_info_size"
prim__queryInfoSize : AnyPtr -> PrimIO Int32
