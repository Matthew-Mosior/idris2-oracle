module Oracle.Types.OracleType

public export
data OracleType
  = OracleTypeVarchar
  | OracleTypeNumber
  | OracleTypeRaw
  | OracleTypeDate
  | OracleTypeTimestamp
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
fromOracleTypeNum 3008 = OracleTypeClob
fromOracleTypeNum 3009 = OracleTypeBlob
fromOracleTypeNum n    = OracleTypeUnknown n
