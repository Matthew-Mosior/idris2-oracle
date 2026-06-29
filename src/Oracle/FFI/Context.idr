module Oracle.FFI.Context

||| Create and initialize the global ODPI-C context.
|||
||| Returns a raw dpiContext pointer.
|||
export %foreign "C:oracle_context_create,oracle-idris"
prim__contextCreate : PrimIO AnyPtr
