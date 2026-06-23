module Oracle.Context

import Oracle.Error
import Oracle.FFI.Context
import Oracle.Types.Context
import Oracle.Types.Error

import PrimIO

||| Initialize the ODPI-C runtime.
|||
export
initialize : IO (Either OracleError OracleContext)
initialize = do
  ptr <- primIO prim__contextCreate
  case prim__nullAnyPtr ptr == 1 of
    True  => do
      lasterr <- getLastError
      pure (Left lasterr)
    False =>
      pure (Right (MkOracleContext ptr))
