module Oracle.Types.BindParameter

import Oracle.Types.Value

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
