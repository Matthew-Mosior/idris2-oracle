module Oracle.FFI.Error

||| Retrieve the last Oracle error code.
|||
export %foreign "C:get_error_code,oracle-idris"
prim__getErrorCode : PrimIO Int32

||| Retrieve the last Oracle error message.
|||
export %foreign "C:get_error_message,oracle-idris"
prim__getErrorMessage : PrimIO String
