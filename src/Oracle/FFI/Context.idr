module Oracle.FFI.Context

||| Create and initialize the global ODPI-C context.
|||
||| Returns a raw dpiContext pointer.
|||
export %foreign "C:oracle_context_create"
prim__contextCreate : PrimIO AnyPtr
