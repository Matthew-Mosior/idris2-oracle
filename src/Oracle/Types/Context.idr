module Oracle.Types.Context

public export
record OracleContext where
  constructor MkOracleContext
  ptr : AnyPtr
