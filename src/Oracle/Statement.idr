module Oracle.Statement

import Control.Monad.Elin
import Control.Monad.MCancel
import Data.ByteString
import Data.Linear.Ref1
import Oracle.Connection
import Oracle.Error
import Oracle.FFI.Bind
import Oracle.FFI.DateTime
import Oracle.FFI.Statement
import Oracle.Internal.Decode
import Oracle.Internal.Pointer
import Oracle.Types.BindParameter
import Oracle.Types.DateTime
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
  result <- runElinIO (withStatement' conn sql)
  case result of
    Right value =>
      case value of
        Left err     =>
          pure (Left err)
        Right value' =>
          pure (Right value')
    Left err    =>
      assert_total $ idris_crash "Oracle.Connection.withStatement: \{show err}"
  where
    acquire : Connection -> String -> F1 World (Either OracleError Statement)
    acquire conn sql =
      ioToF1 (prepare conn sql)
    use : Either OracleError Statement -> F1 World (Either OracleError a)
    use stmt =
      case stmt of
        Left err    =>
          ioToF1 (pure (Left err))
        Right stmt' =>
          ioToF1 (action stmt')
    cleanup : Either OracleError Statement -> F1' World
    cleanup stmt =
      case stmt of
        Left err    =>
          ioToF1 (pure ())
        Right stmt' =>
          ioToF1 (release stmt')
    withStatement' : Connection -> String -> Elin World [] (Either OracleError a)
    withStatement' conn sql =
      bracket (runIO (acquire conn sql))
              (\stmt => runIO (use stmt))
              (\stmt => runIO (cleanup stmt))

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
||| - OracleDate
||| - OracleTimestamp
||| - OracleTimestampTZ
||| - OracleTimestampLTZ
||| - OracleIntervalYM
||| - OracleIntervalDS
|||
||| OracleBytes bindings are not supported as of yet.
|||
export
bindOne : Statement -> BindParameter -> IO (Either OracleError ())
bindOne stmt param =
  case param.value of
    OracleNull            =>
      primIO (prim__bindNull stmt.ptr param.name)
        >>= finish
    OracleString s        =>
      primIO (prim__bindString stmt.ptr param.name s)
        >>= finish
    OracleInt i           =>
      primIO (prim__bindInt64 stmt.ptr param.name i)
        >>= finish
    OracleDouble d        =>
      primIO (prim__bindDouble stmt.ptr param.name d)
        >>= finish
    OracleBool b          =>
      primIO (prim__bindBool stmt.ptr param.name (if b then 1 else 0))
        >>= finish
    OracleClob s          =>
      primIO (prim__bindClob stmt.ptr param.name s)
        >>= finish
    OracleBlob b          =>
      primIO (prim__bindBlob stmt.ptr param.name (toString b))
        >>= finish
    OracleTimestamp ts    =>
      primIO ( prim__bindTimestamp stmt.ptr
                                   param.name
                                   (cast ts.year)
                                   (cast ts.month)
                                   (cast ts.day)
                                   (cast ts.hour)
                                   (cast ts.minute)
                                   (cast ts.second)
                                   (cast ts.nanosecond)
             )
        >>= finish
    OracleTimestampTZ ts  =>
      primIO ( prim__bindTimestampTZ stmt.ptr
                                     param.name
                                     (cast ts.year)
                                     (cast ts.month)
                                     (cast ts.day)
                                     (cast ts.hour)
                                     (cast ts.minute)
                                     (cast ts.second)
                                     (cast ts.nanosecond)
                                     (cast ts.tzHourOffset)
                                     (cast ts.tzMinuteOffset)
             )
        >>= finish
    OracleIntervalYM iv   =>
      primIO ( prim__bindIntervalYM stmt.ptr
                                    param.name
                                    (cast iv.years)
                                    (cast iv.months)
             )
        >>= finish
    OracleIntervalDS iv   =>
      primIO ( prim__bindIntervalDS stmt.ptr
                                    param.name
                                    (cast iv.days)
                                    (cast iv.hours)
                                    (cast iv.minutes)
                                    (cast iv.seconds)
                                    (cast iv.nanoseconds)
             )
        >>= finish
  where
    finish : Int32 -> IO (Either OracleError ())
    finish rc =
      case rc == 0 of
        True =>
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
