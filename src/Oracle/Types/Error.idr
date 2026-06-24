module Oracle.Types.Error

import Derive.Prelude

%language ElabReflection

||| Oracle database error returned from ODPI-C.
|||
||| Every Oracle operation that can fail returns an
||| `OracleError` describing the underlying Oracle
||| error code and message.
|||
public export
record OracleError where
  constructor MkOracleError
  code        : Int32
  message     : String
  fnname      : String
  recoverable : Bool

%runElab derive "OracleError" [Show]

export
invalidrow : OracleError
invalidrow = MkOracleError (-1)
                           "Row decoding failed"
                           "FromRow"
                           False
