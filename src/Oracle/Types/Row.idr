module Oracle.Types.Row

import Oracle.Types.BindParameter
import Oracle.Types.Error
import Oracle.Types.Value

||| Decode a single Oracle value into an Idris type.
|||
||| This interface is the typed counterpart to `ToOracleValue`.
|||
||| It is responsible only for converting a single `OracleValue` into the requested Idris type.
|||
||| Typical instances include:
||| - `String`
||| - `Double`
||| - `Bool`
||| - `ByteString`
||| - `OracleTimestamp`
||| - `OracleTimestampTZ`
||| - `OracleIntervalYM`
||| - `OracleIntervalDS`
|||
||| This interface intentionally does not perform any row-level decoding, as that responsibility belongs to `FromRow`.
|||
||| Example:
|||
||| ```idris
||| implementation FromOracle Double where
|||   fromOracle (OracleNumber n) = Right n
|||   fromOracle value =
|||     Left $
|||       MkOracleError
|||         (-1)
|||         ("Expected NUMBER but got " ++ show value)
|||         "FromOracle Double"
|||         False
||| ```
|||
public export
interface FromOracle a where
  fromOracle : OracleValue -> Either OracleError a

||| Convert an Idris record into a collection of named bind parameters.
|||
||| This interface is intended for values that will be supplied to SQL statements as bind variables.
|||
||| Each returned `BindParameter` associates a named placeholder (such as `:name`) with the Oracle value that should be sent to the database.
|||
||| Unlike `FromOracle`, this interface operates on complete records rather than individual values.
|||
||| Example:
|||
||| ```idris
||| implementation ToRow Person where
|||   toRow person =
|||     [ MkBindParameter ":name" (OracleString person.name)
|||     , MkBindParameter ":age"  (OracleNumber person.age)
|||     ]
||| ```
|||
||| The ordering of bind parameters is not significant when binding by name, but using the SQL declaration order is recommended for readability.
|||
public export
interface ToRow a where
  toRow : a -> List BindParameter

||| Decode a complete database row into an Idris value.
|||
||| A `FromRow` instance describes how an ordered list of `OracleValue`s returned by Oracle should be assembled into an application type.
|||
||| Most implementations simply pattern-match on the expected row shape and delegate the decoding of each individual column to `FromOracle`.
|||
||| Example:
|||
||| ```idris
||| implementation FromRow Person where
|||   fromRow [name, age] = do
|||     name' <- fromOracle name
|||     age'  <- fromOracle age
|||     pure (MkPerson name' age')
|||
|||   fromRow row =
|||     Left $
|||       MkOracleError
|||         (-1)
|||         ("Unexpected PERSON row: " ++ show row)
|||         "Person.fromRow"
|||         False
||| ```
|||
||| This interface is used by the typed query APIs (`query_`, `queryOne`, and `queryExactlyOne`) to transform raw query results into strongly typed Idris values.
|||
public export
interface FromRow a where
  fromRow : List OracleValue -> Either OracleError a
