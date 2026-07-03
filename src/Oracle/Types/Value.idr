module Oracle.Types.Value

import Data.ByteString
import Oracle.Types.DateTime

||| Represents a value exchanged with Oracle.
|||
||| Used for bind parameters and query results.
|||
public export
data OracleValue
  = OracleNull          
  | OracleString String    -- VARCHAR2, CHAR, NVARCHAR2, etc.
  | OracleInt Int64        -- NUMBER
  | OracleDouble Double    -- NUMBER
  | OracleBool Bool        -- BOOLEAN
  | OracleClob String      -- Character large object (CLOB)
  | OracleBlob ByteString  -- Binary large object (BLOB)
  | OracleDate OracleDate
  | OracleTimestamp OracleTimestamp
  | OracleTimestampTZ OracleTimestampTZ
  | OracleTimestampLTZ OracleTimestamp
  | OracleIntervalYM OracleIntervalYM
  | OracleIntervalDS OracleIntervalDS
