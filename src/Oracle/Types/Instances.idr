module Oracle.Types.Instances

import Oracle.Types.Error
import Oracle.Types.Row
import Oracle.Types.Value

implementation FromRow (List OracleValue) where
  fromRow values =
    Right values

implementation FromRow OracleValue where
  fromRow [value] =
    Right value
  fromRow _ =
    Left $
      MkOracleError (-1)
                    "Expected exactly one column"
                    "FromRow OracleValue"
                    False
