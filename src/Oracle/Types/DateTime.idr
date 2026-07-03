module Oracle.Types.DateTime

public export
record OracleDate where
  constructor MkOracleDate
  year   : Int32
  month  : Int32
  day    : Int32
  hour   : Int32
  minute : Int32
  second : Int32

public export
record OracleTimestamp where
  constructor MkOracleTimestamp
  year       : Int32
  month      : Int32
  day        : Int32
  hour       : Int32
  minute     : Int32
  second     : Int32
  nanosecond : Int32

public export
OracleTimestampLTZ : Type
OracleTimestampLTZ = OracleTimestamp

public export
record OracleTimestampTZ where
  constructor MkOracleTimestampTZ
  year           : Int32
  month          : Int32
  day            : Int32
  hour           : Int32
  minute         : Int32
  second         : Int32
  nanosecond     : Int32
  tzHourOffset   : Int32
  tzMinuteOffset : Int32

public export
record OracleIntervalYM where
  constructor MkOracleIntervalYM
  years  : Int32
  months : Int32

public export
record OracleIntervalDS where
  constructor MkOracleIntervalDS
  days        : Int32
  hours       : Int32
  minutes     : Int32
  seconds     : Int32
  nanoseconds : Int32
