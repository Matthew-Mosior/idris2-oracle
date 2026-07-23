module Oracle.Internal.Context

||| Internal context handle.
|||
public export
record OracleContext where
  constructor MkOracleContext
  ptr : AnyPtr
