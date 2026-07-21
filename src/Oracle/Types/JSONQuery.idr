module Oracle.Types.JSONQuery

import Oracle.Types.BindParameter

||| A query whose selected expression is expected to produce a JSON value.
|||
||| The expression is wrapped by queryJSON as:
|||
|||   JSON_SERIALIZE(expression RETURNING CLOB)
|||
||| The resulting CLOB is then returned to Idris as a String.
|||
||| `querybody` should contain the FROM clause and any additional SQL clauses required to identify the rows being queried.
|||
||| For example:
|||
|||   MkJSONQuery
|||     "payload"
|||     "documents"
|||     []
|||
||| Produces SQL equivalent to:
|||
|||   SELECT JSON_SERIALIZE(payload RETURNING CLOB)
|||   FROM documents
|||
public export
record JSONQuery where
  constructor MkJSONQuery
  expression : String
  querybody  : String
  binds      : List BindParameter
