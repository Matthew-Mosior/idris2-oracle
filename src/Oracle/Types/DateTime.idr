module Oracle.Types.DateTime

public export
record OracleDate where
  constructor MkOracleDate
  year   : Int
  month  : Int
  day    : Int
  hour   : Int
  minute : Int
  second : Int

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

public export
OracleTimestampLTZ : Type
OracleTimestampLTZ = OracleTimestamp

public export
record OracleTimestampTZ where
  constructor MkOracleTimestampTZ
  year           : Int
  month          : Int
  day            : Int
  hour           : Int
  minute         : Int
  second         : Int
  nanosecond     : Int
  tzHourOffset   : Int
  tzMinuteOffset : Int

public export
record OracleIntervalYM where
  constructor MkOracleIntervalYM
  years  : Int
  months : Int

public export
record OracleIntervalDS where
  constructor MkOracleIntervalDS
  days        : Int
  hours       : Int
  minutes     : Int
  seconds     : Int
  nanoseconds : Int
