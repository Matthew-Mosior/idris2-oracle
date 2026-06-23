module Oracle.Connection

import Oracle.Error
import Oracle.FFI.Connection
import Oracle.Internal.Pointer
import Oracle.Types.ConnectInfo
import Oracle.Types.Error

||| Establish a connection to Oracle.
|||
export
connect : ConnectInfo -> IO (Either OracleError Connection)
connect cfg = do
  ptr <- primIO $
    prim__connect
      cfg.username
      cfg.password
      (connectString cfg)
  case prim__nullAnyPtr ptr == 1 of
    True  => do
      lasterr <- getLastError
      pure (Left lasterr)
    False =>
      pure (Right (MkConnection ptr))
  where
    connectString : ConnectInfo -> String
    connectString cfg =
      cfg.host      ++
      ":"           ++
      show cfg.port ++
      "/"           ++
      cfg.service

||| Close an Oracle connection.
|||
export
disconnect : Connection -> IO ()
disconnect conn =
  primIO $
    prim__disconnect conn.ptr
