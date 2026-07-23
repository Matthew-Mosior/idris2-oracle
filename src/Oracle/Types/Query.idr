module Oracle.Types.Query

import Oracle.Types.BindParameter
import Oracle.Types.QueryColumn

||| Represents a SQL query executed by the Oracle client.
|||
||| `columns` specifies the expressions in the SELECT projection.
|||
||| Each expression may either be selected normally with `Column`, or serialized as JSON text with `JSONColumn`.
|||
||| `querybody` contains the FROM clause and any additional SQL clauses required to construct the query, such as WHERE, ORDER BY, GROUP BY, or JOIN clauses.
|||
||| `binds` contains the bind parameters used by the SQL statement.
|||
||| For example:
|||
|||   MkQuery
|||     [ Column "id"
|||     , Column "name"
|||     , JSONColumn "profile"
|||     ]
|||     "people WHERE active = :active ORDER BY id"
|||     [MkBindParameter ":active" (OracleBool True)]
|||
||| Renders to SQL equivalent to:
|||
|||   SELECT id, name, JSON_SERIALIZE(profile RETURNING CLOB)
|||   FROM people
|||   WHERE active = :active
|||   ORDER BY id
|||
public export
record Query where
  constructor MkQuery
  columns   : List QueryColumn
  querybody : String
  binds     : List BindParameter
