module Oracle.Types.ColumnInfo

import Oracle.Types.OracleType

public export
record ColumnInfo where
  constructor MkColumnInfo
  name       : String
  oracletype : OracleType
  size       : Nat
  nullable   : Bool
