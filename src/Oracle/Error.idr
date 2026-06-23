module Oracle.Error

import Oracle.FFI.Error
import Oracle.Types.Error

||| Retrieve the most recent Oracle error.
|||
export
getLastError : IO OracleError
getLastError = do
  code <- primIO prim__getErrorCode
  msg  <- primIO prim__getErrorMessage
  pure $
    MkOracleError code
                  msg
                  "unknown"
                  False
