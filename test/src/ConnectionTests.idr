module ConnectionTests

import Oracle
import System

export
username : String
username = "idris"

export
password : String
password = "idris"

export
host : String
host = "127.0.0.1"

export
port : Nat
port = 1521

export
service : String
service = "FREEPDB1"

||| Connection information for the Oracle integration test database.
|||
||| This configuration matches the Docker container created by `startup.sh`.
|||
||| Username:
||| * idris
|||
||| Password:
||| * idris
|||
||| Host:
||| * localhost
|||
||| Port:
||| * 1521
|||
||| Service:
||| * FREEPDB1
|||
export
connectinfo : ConnectInfo
connectinfo =
  MkConnectInfo
    username
    password
    host
    port
    service

||| Verify that a connection can be opened using valid credentials.
|||
||| This test succeeds if `connect` returns `Right`.
|||
export
test_OpenConnection : ConnectInfo -> IO ()
test_OpenConnection cfg = do
  result <- connect cfg
  case result of
    Left err =>
      die (show err)
    Right conn => do
      _ <- disconnect conn
      pure ()

||| Verify that `withConnection` opens and automatically releases the Oracle connection.
|||
||| The body performs a trivial query to prove the connection is usable.
|||
export
test_WithConnection : ConnectInfo -> IO ()
test_WithConnection cfg = do
  result <-
    withConnection cfg $ \conn =>
      execute_
        conn
        "SELECT 1 FROM dual"
        []
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure ()

||| Verify that multiple connections may be opened and closed
||| sequentially.
|||
||| This exercises repeated allocation and cleanup of Oracle
||| connection handles.
|||
export
test_SequentialConnections : ConnectInfo -> IO ()
test_SequentialConnections cfg = do
  let
    loop : Nat -> IO ()
    loop Z     =
      pure ()
    loop (S k) = do
      result <- connect cfg
      case result of
        Left err   =>
          die (show err)
        Right conn => do
          _ <- disconnect conn
          loop k
  loop 10

||| Verify that connecting with an invalid password returns an Oracle error instead of establishing a connection.
|||
export
test_InvalidPassword : ConnectInfo -> IO ()
test_InvalidPassword cfg = do
  let badcfg = { password := "definitely-wrong" } cfg
  result <- connect badcfg
  case result of
    Left _     =>
      pure ()
    Right conn => do
      _ <- disconnect conn
      die "Connection unexpectedly succeeded."

||| Verify that connecting to an unknown Oracle service returns an error.
|||
export
test_InvalidService : ConnectInfo -> IO ()
test_InvalidService cfg = do
  let badCfg = { service := "THIS_SERVICE_DOES_NOT_EXIST" } cfg
  result <- connect badCfg
  case result of
    Left _     =>
      pure ()
    Right conn => do
      _ <- disconnect conn
      die "Connection unexpectedly succeeded."
