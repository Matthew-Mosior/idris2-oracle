module Oracle.Query

import Oracle.Statement
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
--          Query Raw
--------------------------------------------------------------------------------

||| Execute a query and return rows as raw Oracle values.
|||
||| Each row is represented as:
|||
||| ```idris
||| List OracleValue
||| ```
|||
||| This function provides untyped decoding, use `query_` for typed decoding.
|||
export covering
queryRaw : Connection -> String -> List BindParameter -> IO (Either OracleError (List (List OracleValue)))
queryRaw conn sql params = query conn sql params

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
