module Oracle.Statement

import Control.Monad.Elin
import Control.Monad.MCancel
import Data.ByteString
import Oracle.Connection
import Oracle.Error
import Oracle.FFI.Bind
import Oracle.FFI.Statement
import Oracle.Internal.Decode
import Oracle.Internal.Pointer
import Oracle.Types.BindParameter
import Oracle.Types.Error
import Oracle.Types.Value

%default total

--------------------------------------------------------------------------------
--          Prepare / Release
--------------------------------------------------------------------------------

||| Prepare a SQL statement.
|||
||| The returned statement must eventually be released with `release` or managed with `withStatement`.
|||
export
prepare : Connection -> String -> IO (Either OracleError Statement)
prepare conn sql = do
  ptr <- primIO (prim__prepareStmt conn.ptr sql)
  case prim__nullAnyPtr ptr == 1 of
    True => do
      lasterr <- getLastError
      pure (Left lasterr)
    False =>
      pure (Right $ MkStatement ptr)

||| Release a prepared statement.
|||
||| This decrements the underlying ODPI-C statement reference count.
|||
export
release : Statement -> IO ()
release stmt =
  primIO (prim__releaseStmt stmt.ptr)

--------------------------------------------------------------------------------
--          With Statement
--------------------------------------------------------------------------------

||| Prepare a statement, execute an action, and guarantee that the statement is released afterwards.
|||
||| This is the preferred way to work with prepared statements.
|||
||| Prepare a statement, execute an action, and guarantee cleanup.
|||
||| The statement is released regardless of whether the action succeeds or fails.
|||
export
withStatement : Connection -> String -> (Statement -> IO (Either OracleError a)) -> IO (Either OracleError a)
withStatement conn sql action = do
  estmt <- prepare conn sql
  case estmt of
    Left err =>
      pure (Left err)
    Right stmt => do
      res <- runElinIO (withStatement' stmt)
      case res of
        Left err =>
          assert_total $ idris_crash "Oracle.Statement.withStatement: \{show err}"
        Right result =>
          pure result
  where
    acquire : Statement -> Elin World [] Statement
    acquire stmt =
      liftIO $ pure stmt
    cleanup : Statement -> Elin World [] ()
    cleanup stmt =
      liftIO $ release stmt
    use : Statement -> Elin World [] (Either OracleError a)
    use stmt =
      liftIO $ action stmt
    withStatement' : Statement -> Elin World [] (Either OracleError a)
    withStatement' stmt =
      bracket (acquire stmt)
              use
              cleanup

--------------------------------------------------------------------------------
--          Execute
--------------------------------------------------------------------------------

||| Execute a prepared statement.
|||
||| For SELECT statements this executes the query.
||| For INSERT/UPDATE/DELETE statements this performs the update.
|||
export
execute : Statement -> IO (Either OracleError ())
execute stmt = do
  rc <- primIO (prim__executeStmt stmt.ptr)
  case rc == 0 of
    True  =>
      pure (Right ())
    False => do
      lasterr <- getLastError
      pure (Left lasterr)

--------------------------------------------------------------------------------
--          Binding
--------------------------------------------------------------------------------

||| Bind a single named parameter.
|||
||| Supported value types:
||| - OracleNull
||| - OracleString
||| - OracleInt
||| - OracleDouble
||| - OracleBool
||| - OracleClob
||| - OracleBlob
|||
||| OracleBytes bindings are not supported as of yet.
|||
export
bindOne : Statement -> BindParameter -> IO (Either OracleError ())
bindOne stmt param =
  case param.value of
    OracleNull     => do
      rc <- primIO (prim__bindNull stmt.ptr param.name)
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleString s => do
      rc <- primIO (prim__bindString stmt.ptr param.name s)
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleInt i    => do
      rc <- primIO (prim__bindInt64 stmt.ptr param.name i)
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleDouble d => do
      rc <- primIO (prim__bindDouble stmt.ptr param.name d)
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleBool b   => do
      rc <- primIO (prim__bindBool stmt.ptr param.name (if b then 1 else 0))
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleClob s   => do
      rc <- primIO (prim__bindClob stmt.ptr param.name s)
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)
    OracleBlob b   => do
      rc <- primIO (prim__bindBlob stmt.ptr param.name (toString b))
      case rc == 0 of
        True  =>
          pure (Right ())
        False => do
          lasterr <- getLastError
          pure (Left lasterr)

||| Bind a collection of named parameters.
|||
export
bind : Statement -> List BindParameter -> IO (Either OracleError ())
bind stmt []        =
  pure (Right ())
bind stmt (x :: xs) = do
  res <- bindOne stmt x
  case res of
    Left err =>
      pure (Left err)
    Right () =>
      bind stmt xs

--------------------------------------------------------------------------------
--          Fetching
--------------------------------------------------------------------------------

||| Fetch a single row from the current result set.
|||
||| Returns:
||| - Right Nothing when no rows remain.
||| - Right (Just row) when a row was fetched.
||| - Left OracleError on failure.
|||
export covering
fetchRow : Statement -> IO (Either OracleError (Maybe (List OracleValue)))
fetchRow stmt = do
  rc <- primIO (prim__fetch stmt.ptr)
  case compare rc 0 of
    LT =>
      Left <$> getLastError
    EQ =>
      pure (Right Nothing)
    GT => do
      count <- primIO (prim__columnCount stmt.ptr)
      row   <- go count 0 []
      case row of
        Left err     =>
          pure (Left err)
        Right values =>
          pure $
            Right $
              Just values
  where
    go : Int32 -> Int32 -> List OracleValue -> IO (Either OracleError (List OracleValue))
    go count index acc =
      case index >= count of
        True  =>
          pure (Right $ reverse acc)
        False => do
          value <- decodeColumn stmt.ptr index
          case value of
            Left err =>
              pure (Left err)
            Right v  =>
              go count
                 (index + 1)
                 (v :: acc)

--------------------------------------------------------------------------------
--          Fetch All
--------------------------------------------------------------------------------

||| Fetch all remaining rows from the current result set.
|||
export covering
fetchRaw : Statement -> IO (Either OracleError (List (List OracleValue)))
fetchRaw stmt =
  loop []
  where
    loop : List (List OracleValue) -> IO (Either OracleError (List (List OracleValue)))
    loop acc = do
      row <- fetchRow stmt
      case row of
        Left err            =>
          pure (Left err)
        Right Nothing       =>
          pure (Right $ reverse acc)
        Right (Just values) =>
          loop (values :: acc)

--------------------------------------------------------------------------------
--          Query
--------------------------------------------------------------------------------

||| Execute a SQL query and return all rows.
|||
export covering
query : Connection -> String -> List BindParameter -> IO (Either OracleError (List (List OracleValue)))
query conn sql params =
  withStatement conn sql $ \stmt => do
    bound <- bind stmt params
    case bound of
      Left err =>
        pure (Left err)
      Right () => do
        executed <- execute stmt
        case executed of
          Left err =>
            pure (Left err)
          Right () =>
            fetchRaw stmt
