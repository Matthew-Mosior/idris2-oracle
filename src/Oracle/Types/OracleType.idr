module Oracle.Types.OracleType

import Derive.Prelude

%language ElabReflection

public export
data OracleType
  = OracleTypeVarchar
  | OracleTypeNumber
  | OracleTypeRaw
  | OracleTypeTimestamp
  | OracleTypeTimestampTZ
  | OracleTypeIntervalYM
  | OracleTypeIntervalDS
  | OracleTypeClob
  | OracleTypeBlob
  | OracleTypeUnknown Int32

%runElab derive "OracleType" [Eq,Ord,Show]

||| Convert an ODPI-C Oracle type number into an Idris representation.
|||
export
fromOracleTypeNum : Int32 -> OracleType
fromOracleTypeNum 2001 = OracleTypeVarchar
fromOracleTypeNum 2006 = OracleTypeRaw
fromOracleTypeNum 2010 = OracleTypeNumber
fromOracleTypeNum 2012 = OracleTypeTimestamp
fromOracleTypeNum 2013 = OracleTypeTimestampTZ
fromOracleTypeNum 2015 = OracleTypeIntervalDS
fromOracleTypeNum 2016 = OracleTypeIntervalYM
fromOracleTypeNum 2017 = OracleTypeClob
fromOracleTypeNum 2019 = OracleTypeBlob
fromOracleTypeNum n    = OracleTypeUnknown n
