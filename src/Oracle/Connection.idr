module Oracle.Connection

import Control.Monad.Elin
import Control.Monad.MCancel
import Data.Linear.Ref1
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
  ptr <- primIO (prim__connect cfg.username cfg.password (connectString cfg))
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
  primIO (prim__disconnect conn.ptr)

||| Establish a connection, execute an action, and guarantee that the connection is closed afterwards.
|||
||| This function provides safe resource management for Oracle connections, and should generally be preferred over calling `connect` and `disconnect` manually.
|||
||| The connection is:
||| 1. Established.
||| 2. Passed to the supplied action.
||| 3. Disconnected regardless of whether the action succeeds or fails.
|||
||| Example:
|||
||| ```idris
||| withConnection cfg $ \conn =>
|||   query_ conn
|||          "select * from employees"
|||          []
||| ```
|||
export
withConnection : ConnectInfo -> (Connection -> IO (Either OracleError a)) -> IO (Either OracleError a)
withConnection cfg action = do
  result <- runElinIO (withConnection' cfg)
  case result of
    Right value =>
      case value of
        Left err     =>
          pure (Left err)
        Right value' =>
          pure (Right value')
    Left err    =>
      assert_total $ idris_crash "Oracle.Connection.withConnection: \{show err}"
  where
    acquire : ConnectInfo -> F1 World (Either OracleError Connection)
    acquire cfg = do
      ioToF1 (connect cfg)
    use : Either OracleError Connection -> F1 World (Either OracleError a)
    use conn =
      case conn of
        Left err    =>
          ioToF1 (pure (Left err))
        Right conn' => 
          ioToF1 (action conn')
    release : Either OracleError Connection -> F1' World
    release conn =
      case conn of
        Left err    =>
          ioToF1 (pure ())
        Right conn' =>
          ioToF1 (disconnect conn')
    withConnection' : ConnectInfo -> Elin World [] (Either OracleError a)
    withConnection' cfg =
      bracket
        (runIO (acquire cfg))
        (\conn => runIO (use conn))
        (\conn => runIO (release conn))
