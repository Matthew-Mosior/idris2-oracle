module Oracle.Internal.JSONQuery

import Oracle.Types.JSONQuery

||| Construct the SQL used internally to retrieve a JSON value as a CLOB (String).
|||
export
buildJSONQuerySQL : JSONQuery -> String
buildJSONQuerySQL query =
  "SELECT JSON_SERIALIZE(" ++
  expression query         ++
  " RETURNING CLOB) FROM " ++
  querybody query
