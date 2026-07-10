module Oracle.Query

import Oracle.Statement
import Oracle.Internal.Either
import Oracle.Internal.Pointer
import Oracle.Types.BindParameter
import Oracle.Types.Error
import Oracle.Types.Row
import Oracle.Types.Value

%default total

--------------------------------------------------------------------------------
--          Decode Rows
--------------------------------------------------------------------------------

||| Decode a list of raw Oracle rows into a list of typed values.
|||
||| Each raw row returned from Oracle is passed through the `FromRow` instance for the requested type.
|||
||| Decoding proceeds from the first row to the last row.
|||
||| If any row fails to decode, decoding stops immediately and the first `OracleError` is returned.
|||
||| This function is used internally by `query_`, but is exported so callers can decode results obtained from `queryRaw` manually.
|||
||| Example:
|||
||| ```idris
||| decodeRows
|||   [ [OracleInt 1, OracleString "Alice"]
|||   , [OracleInt 2, OracleString "Bob"]
|||   ]
||| ```
|||
export
decodeRows : FromRow a => List (List OracleValue) -> Either OracleError (List a)
decodeRows rows =
  go rows []
  where
    go : List (List OracleValue) -> List a -> Either OracleError (List a)
    go []            acc =
      Right (reverse acc)
    go (row :: rest) acc =
      case fromRow row of
        Left err =>
          Left err
        Right value =>
          go rest (value :: acc)

--------------------------------------------------------------------------------
--          Untyped Query
--------------------------------------------------------------------------------

||| Execute a SQL query while automatically managing the prepared statement lifetime.
|||
||| This is the raw query API.
|||
||| The statement is:
||| 1. Prepared.
||| 2. Bound with parameters.
||| 3. Executed.
||| 4. Fetched.
||| 5. Released.
|||
||| Returned rows contain raw Oracle values.
|||
export covering
queryRaw : Connection -> String -> List BindParameter -> IO (Either OracleError (List (List OracleValue)))
queryRaw conn sql params =
  withStatement conn sql $ \stmt => do
    bind stmt params >>== \_ =>
      execute stmt >>== \_ =>
        fetchRaw stmt

--------------------------------------------------------------------------------
--          Typed Query
--------------------------------------------------------------------------------

||| Execute a query and decode every returned row.
|||
||| The target type must provide a `FromRow` implementation describing how to convert `List OracleValue` into the target value.
|||
||| Example:
|||
||| ```idris
||| record Employee where
|||   constructor MkEmployee
|||   id   : Int64
|||   name : String
|||
||| implementation FromRow Employee where
|||   fromRow [OracleInt id, OracleString name] =
|||       Right (MkEmployee id name)
|||   fromRow _ =
|||       Left invalidRow
|||
||| employees <- query_ conn
|||                    "select id,name from employees"
|||                    []
||| ```
|||
export covering
query_ : FromRow a => Connection -> String -> List BindParameter -> IO (Either OracleError (List a))
query_ conn sql params = do
  rows <- queryRaw conn sql params
  case rows of
    Left err     =>
      pure (Left err)
    Right values =>
      pure (decodeRows values)

--------------------------------------------------------------------------------
--          Single Row Query
--------------------------------------------------------------------------------

||| Execute a query and decode at most a single row.
|||
||| Returns:
||| - Left OracleError if execution fails.
||| - Right Nothing if no rows were returned.
||| - Right (Just value) for the first row.
|||
||| If multiple rows are returned, only the first row is used and the remainder are ignored.
|||
||| Example:
|||
||| ```idris
||| employee <-
|||   queryOne
|||     conn
|||     "select id,name
|||        from employees
|||       where id = :id"
|||     [ MkBindParameter "id"
|||         (OracleInt 1)
|||     ]
||| ```
|||
export covering
queryOne : FromRow a => Connection -> String -> List BindParameter -> IO (Either OracleError (Maybe a))
queryOne conn sql params = do
  result <- query_ conn sql params
  case result of
    Left err       =>
      pure (Left err)
    Right []       =>
      pure (Right Nothing)
    Right (x :: _) =>
      pure (Right (Just x))

||| Execute a query and require exactly one row.
|||
||| Returns:
||| - Left OracleError if query execution fails.
||| - Left OracleError if no rows are returned.
||| - Left OracleError if more than one row is returned.
||| - Right value if exactly one row is returned.
|||
||| This function is useful when querying by a primary key or other unique identifier.
|||
||| Example:
|||
||| ```idris
||| employee <-
|||   queryExactlyOne
|||     conn
|||     "select id,name
|||        from employees
|||       where id = :id"
|||     [ MkBindParameter "id"
|||         (OracleInt 1)
|||     ]
||| ```
|||
export covering
queryExactlyOne : FromRow a => Connection -> String -> List BindParameter -> IO (Either OracleError a)
queryExactlyOne conn sql params = do
  result <- query_ conn sql params
  case result of
    Left err            =>
      pure (Left err)
    Right []            =>
      pure $
        Left $
          MkOracleError
            (-1)
            "Expected exactly one row but query returned no rows"
            "Oracle.Query.queryExactlyOne"
            False
    Right [value]       =>
      pure (Right value)
    Right (_ :: _ :: _) =>
      pure $
        Left $
          MkOracleError
            (-1)
            "Expected exactly one row but query returned multiple rows"
            "Oracle.Query.queryExactlyOne"
            False

--------------------------------------------------------------------------------
--          Execute Statement That Returns No Rows
--------------------------------------------------------------------------------

||| Execute a statement that does not return rows.
|||
||| This function is intended for:
||| - INSERT
||| - UPDATE
||| - DELETE
||| - MERGE
||| - DDL statements
|||
||| The statement is automatically:
||| 1. Prepared.
||| 2. Bound.
||| 3. Executed.
||| 4. Released.
|||
||| Example:
|||
||| ```idris
||| execute_
|||   conn
|||   "insert into employees(id,name)
|||    values (:id,:name)"
|||   [ MkBindParameter "id"
|||       (OracleInt 1)
|||   , MkBindParameter "name"
|||       (OracleString "Alice")
|||   ]
||| ```
|||
export
execute_ : Connection -> String -> List BindParameter -> IO (Either OracleError ())
execute_ conn sql params =
  withStatement conn sql $ \stmt =>
    bind stmt params >>== \_ =>
      execute stmt
