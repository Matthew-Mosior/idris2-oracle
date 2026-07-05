module Oracle.Types.ColumnInfo

import Derive.Prelude
import Oracle.Types.OracleType

%language ElabReflection

public export
record ColumnInfo where
  constructor MkColumnInfo
  name       : String
  oracletype : OracleType
  size       : Nat
  nullable   : Bool

%runElab derive "ColumnInfo" [Eq,Ord,Show]
