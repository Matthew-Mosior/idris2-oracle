module ConnectionTests

import ConnectInfoTest
import Oracle
import System

||| Verify that a connection can be opened using valid credentials.
|||
||| This test succeeds if `connect` returns `Right`.
|||
export
test_OpenConnection : ConnectInfo -> IO (Either OracleError ())
test_OpenConnection cfg = do
  result <- connect cfg
  case result of
    Left err =>
      die (show err)
    Right conn => do
      _ <- disconnect conn
      pure (Right ())

||| Verify that `withConnection` opens and automatically releases the Oracle connection.
|||
||| The body performs a trivial query to prove the connection is usable.
|||
export
test_WithConnection : ConnectInfo -> IO (Either OracleError ())
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
      pure (Right ())

||| Verify that multiple connections may be opened and closed
||| sequentially.
|||
||| This exercises repeated allocation and cleanup of Oracle
||| connection handles.
|||
export
test_SequentialConnections : ConnectInfo -> IO (Either OracleError ())
test_SequentialConnections cfg = do
  let
    loop : Nat -> IO (Either OracleError ())
    loop Z     =
      pure (Right ())
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
test_InvalidPassword : ConnectInfo -> IO (Either OracleError ())
test_InvalidPassword cfg = do
  let badcfg = { password := "definitely-wrong" } cfg
  result <- connect badcfg
  case result of
    Left _     =>
      pure (Right ())
    Right conn => do
      _ <- disconnect conn
      die "Connection unexpectedly succeeded."

||| Verify that connecting to an unknown Oracle service returns an error.
|||
export
test_InvalidService : ConnectInfo -> IO (Either OracleError ())
test_InvalidService cfg = do
  let badCfg = { service := "THIS_SERVICE_DOES_NOT_EXIST" } cfg
  result <- connect badCfg
  case result of
    Left _     =>
      pure (Right ())
    Right conn => do
      _ <- disconnect conn
      die "Connection unexpectedly succeeded."
