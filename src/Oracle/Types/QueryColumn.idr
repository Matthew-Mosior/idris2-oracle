module Oracle.Types.QueryColumn

||| Describes a single expression selected by a Query.
|||
||| `Column` selects the expression exactly as provided.
|||
||| `JSONColumn` selects the expression after wrapping it in `JSON_SERIALIZE(... RETURNING CLOB)`.
|||
||| JSON columns are therefore returned to Idris as CLOB-backed text, allowing them to be decoded as ordinary String values or passed to a `FromJSON` implementation.
|||
||| For example:
|||
|||   JSONColumn "profile"
|||
||| renders as:
|||
|||   JSON_SERIALIZE(profile RETURNING CLOB)
|||
public export
data QueryColumn
  = Column String
  | JSONColumn String
