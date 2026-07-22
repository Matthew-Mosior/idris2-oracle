module Oracle.Query

import JSON
import Oracle.Statement
import Oracle.Internal.Either
import Oracle.Internal.JSONQuery
import Oracle.Internal.Pointer
import Oracle.Types.BindParameter
import Oracle.Types.Error
import Oracle.Types.JSONQuery
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

||| Execute a JSON query and return the serialized JSON document.
|||
||| The JSONQuery expression is wrapped internally as:
|||
|||   JSON_SERIALIZE(expression RETURNING CLOB)
|||
||| The query must return exactly one row containing one non-null JSON value.
|||
||| The returned JSON is represented as a String so that it can be decoded using the Idris2 JSON library.
|||
||| Example:
|||
|||   queryJSON conn
|||     (MkJSONQuery
|||       "payload"
|||       "documents WHERE id = :id"
|||       [MkBindParameter "id" (OracleNumber 42)])
|||
export covering
queryJSON : Connection -> JSONQuery -> IO (Either OracleError String)
queryJSON conn jsonquery = do
  result <- query conn (buildJSONQuerySQL jsonquery) jsonquery.binds
  case result of
    Left err   =>
      pure (Left err)
    Right rows => do
      case rows of
        []    =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned no rows"
                "Oracle.Query.queryJSON"
                False
        [row] =>
          case row of
            []                   =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    "JSON query returned no columns"
                    "Oracle.Query.queryJSON"
                    False
            [OracleNull]         =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    "JSON query returned NULL"
                    "Oracle.Query.queryJSON"
                    False
            [OracleClob value]   =>
              pure (Right value)
            [OracleString value] =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    "JSON query returned an OracleString"
                    "Oracle.Query.queryJSON"
                    False
            _                    =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    "JSON query returned an unexpected value type"
                    "queryJSON"
                    False
        _     =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned more than one row; use queryJSONList"
                "queryJSON"
                False

||| Execute a JSON query and return all serialized JSON documents.
|||
||| Each row must contain exactly one non-null JSON value.
|||
||| This is the multi-row counterpart to queryJSON.
|||
export covering
queryJSONList : Connection -> JSONQuery -> IO (Either OracleError (List String))
queryJSONList conn jsonquery = do
  result <- query conn (buildJSONQuerySQL jsonquery) jsonquery.binds
  case result of
    Left err   =>
      pure (Left err)
    Right rows =>
      decodeRows rows
  where
    decodeRows : List (List OracleValue) -> IO (Either OracleError (List String))
    decodeRows []            =
      pure (Right [])
    decodeRows (row :: rest) =
      case row of
        [OracleClob value]   => do
          tailresult <- decodeRows rest
          case tailresult of
            Left err     =>
              pure (Left err)
            Right values =>
              pure (Right (value :: values))
        [OracleString value] =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned an OracleString"
                "Oracle.Query.queryJSONList"
                False
        [OracleNull]         =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned NULL"
                "Oracle.Query.queryJSONList"
                False
        []                   =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned no columns"
                "Oracle.Query.queryJSONList"
                False
        _                    =>
          pure $
            Left $
              MkOracleError
                (-1)
                "JSON query returned an unexpected number or type of columns"
                "Oracle.Query.queryJSONList"
                False

||| Execute a JSON query and decode the resulting JSON document.
|||
||| The result is decoded using the FromJSON implementation for `a`.
|||
||| This allows callers to query Oracle JSON directly into an Idris data type with a derived FromJSON implementation.
|||
export covering
queryJSONAs : FromJSON a => Connection -> JSONQuery -> IO (Either OracleError a)
queryJSONAs conn query = do
  result <- queryJSON conn query
  case result of
    Left err   =>
      pure (Left err)
    Right json =>
      case decode json of
        Left jsonerr =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Failed to decode JSON: " ++ show jsonerr)
                "Oracle.Query.queryJSONAs"
                False
        Right value  =>
          pure (Right value)

||| Execute a JSON query and decode all resulting JSON documents.
|||
||| Each row is decoded using the FromJSON implementation for `a`.
|||
export covering
queryJSONListAs : FromJSON a => Connection -> JSONQuery -> IO (Either OracleError (List a))
queryJSONListAs conn query = do
  result <- queryJSONList conn query
  case result of
    Left err         =>
      pure (Left err)
    Right jsonvalues =>
      decodeValues jsonvalues
  where
    decodeValues : List String -> IO (Either OracleError (List a))
    decodeValues []             =
      pure (Right [])
    decodeValues (json :: rest) =
      case decode json of
        Left jsonerr =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Failed to decode JSON: " ++ show jsonerr)
                "Oracle.Query.queryJSONListAs"
                False
        Right value  => do
          tailresult <- decodeValues rest
          case tailresult of
            Left err     =>
              pure (Left err)
            Right values =>
              pure (Right (value :: values))

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
