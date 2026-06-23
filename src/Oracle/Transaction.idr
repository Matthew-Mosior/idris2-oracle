module Oracle.Transaction

import Oracle.Error
import Oracle.FFI.Transaction
import Oracle.Internal.Pointer
import Oracle.Types.Error

%default total

--------------------------------------------------------------------------------
--          Commit
--------------------------------------------------------------------------------

||| Commit the current transaction on a connection.
|||
||| All changes made since the last commit or rollback become permanent.
|||
||| Returns:
||| - Right () on success.
||| - Left OracleError on failure.
|||
export
commit : Connection -> IO (Either OracleError ())
commit conn = do
  rc <- primIO (prim__commit conn.ptr)
  case rc == 0 of
    True  =>
      pure (Right ())
    False => do
      lasterr <- getLastError
      pure (Left lasterr)

--------------------------------------------------------------------------------
--          Rollback
--------------------------------------------------------------------------------

||| Roll back the current transaction on a connection.
|||
||| All changes made since the last commit or rollback are discarded.
|||
||| Returns:
||| - Right () on success.
||| - Left OracleError on failure.
|||
export
rollback : Connection -> IO (Either OracleError ())
rollback conn = do
  rc <- primIO (prim__rollback conn.ptr)
  case rc == 0 of
    True  =>
      pure (Right ())
    False => do
      lasterr <- getLastError
      pure (Left lasterr)

--------------------------------------------------------------------------------
--          Transaction Bracket
--------------------------------------------------------------------------------

||| Execute an action inside a transaction.
|||
||| The transaction behavior is:
||| - If the action returns Right -> commit is performed.
||| - If the action returns Left -> rollback is performed.
|||
||| The original error is preserved if rollback succeeds.
|||
||| Example:
|||
||| ```idris
||| withTransaction conn $ do
|||   execute stmt1
|||   execute stmt2
||| ```
|||
export
withTransaction : Connection -> IO (Either OracleError a) -> IO (Either OracleError a)
withTransaction conn action = do
  result <- action
  case result of
    Left err    => do
      _ <- rollback conn
      pure (Left err)
    Right value => do
      committed <- commit conn
      case committed of
        Left err =>
          pure (Left err)
        Right () =>
          pure (Right value)
