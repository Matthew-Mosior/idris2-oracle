module Oracle.Internal.Query

import Data.String
import Oracle.Types.Query
import Oracle.Types.QueryColumn

||| Render a single query column into its SQL representation.
|||
||| `Column` leaves the supplied expression unchanged.
|||
||| `JSONColumn` wraps the supplied expression with `JSON_SERIALIZE(... RETURNING CLOB)` so that Oracle returns the JSON value as CLOB text rather than as a native Oracle JSON value.
|||
public export
renderQueryColumn : QueryColumn -> String
renderQueryColumn (Column expression)     =
  expression
renderQueryColumn (JSONColumn expression) =
  "JSON_SERIALIZE(" ++
  expression        ++
  " RETURNING CLOB)"

||| Construct the SQL statement represented by a Query.
|||
||| The query columns are rendered into the SELECT projection and joined with commas.
|||
||| The query body is appended after FROM and is expected to contain the table expression and any additional SQL clauses.
|||
||| For example:
|||
|||   buildQuerySQL $
|||     MkQuery
|||       [Column "id", JSONColumn "profile"]
|||       "people"
|||       []
|||
||| Produces:
|||
|||   SELECT id, JSON_SERIALIZE(profile RETURNING CLOB) FROM people
|||
public export
buildQuerySQL : Query -> String
buildQuerySQL query =
  "SELECT "                                           ++
  joinBy ", " (map renderQueryColumn (columns query)) ++
  " FROM "                                            ++
  querybody query
