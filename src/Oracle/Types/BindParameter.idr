module Oracle.Types.BindParameter

import Derive.Prelude
import Oracle.Types.Value

%language ElabReflection

||| Named bind parameter.
|||
||| Example:
|||
||| :dept is represented as MkBindParameter "dept" (OracleInt 10)
|||
public export
record BindParameter where
  constructor MkBindParameter
  name  : String
  value : OracleValue

%runElab derive "BindParameter" [Eq,Ord,Show]
