module Oracle.Types.DateTime

public export
record OracleDate where
  constructor MkOracleDate
  year  : Int
  month : Int
  day   : Int

public export
record OracleTimestamp where
  constructor MkOracleTimestamp
  year       : Int
  month      : Int
  day        : Int
  hour       : Int
  minute     : Int
  second     : Int
  nanosecond : Int
