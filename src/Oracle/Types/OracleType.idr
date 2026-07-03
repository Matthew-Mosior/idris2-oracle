module Oracle.Types.OracleType

public export
data OracleType
  = OracleTypeVarchar
  | OracleTypeNumber
  | OracleTypeRaw
  | OracleTypeDate
  | OracleTypeTimestamp
  | OracleTypeTimestampTZ
  | OracleTypeTimestampLTZ
  | OracleTypeIntervalYM
  | OracleTypeIntervalDS
  | OracleTypeClob
  | OracleTypeBlob
  | OracleTypeUnknown Int32

||| Convert an ODPI-C Oracle type number into an Idris representation.
|||
export
fromOracleTypeNum : Int32 -> OracleType
fromOracleTypeNum 3001 = OracleTypeVarchar
fromOracleTypeNum 3002 = OracleTypeNumber
fromOracleTypeNum 3006 = OracleTypeRaw
fromOracleTypeNum 3007 = OracleTypeDate
fromOracleTypeNum 3011 = OracleTypeTimestamp
fromOracleTypeNum 3013 = OracleTypeTimestampTZ
fromOracleTypeNum 3014 = OracleTypeTimestampLTZ
fromOracleTypeNum 3015 = OracleTypeIntervalDS
fromOracleTypeNum 3016 = OracleTypeIntervalYM
fromOracleTypeNum 3008 = OracleTypeClob
fromOracleTypeNum 3009 = OracleTypeBlob
fromOracleTypeNum n    = OracleTypeUnknown n
