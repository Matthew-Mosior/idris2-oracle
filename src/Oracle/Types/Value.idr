module Oracle.Types.Value

import Data.ByteString
import Derive.Prelude
import Oracle.Types.DateTime

%language ElabReflection

||| Represents a value exchanged with Oracle.
|||
||| Used for bind parameters and query results.
|||
public export
data OracleValue
  = OracleNull          
  | OracleString      String      -- VARCHAR2, CHAR, NVARCHAR2, etc.
  | OracleNumber      Double      -- NUMBER
  | OracleBool        Bool        -- BOOLEAN
  | OracleClob        String      -- Character large object (CLOB)
  | OracleBlob        ByteString  -- Binary large object (BLOB)
  | OracleTimestamp   OracleTimestamp
  | OracleTimestampTZ OracleTimestampTZ
  | OracleIntervalYM  OracleIntervalYM
  | OracleIntervalDS  OracleIntervalDS

%runElab derive "OracleValue" [Eq,Ord,Show]
