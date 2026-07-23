module PersonRow

import Data.ByteString
import Derive.Prelude
import Oracle
import Oracle.Types.DateTime

%language ElabReflection

public export
implementation FromOracle String where
  fromOracle (OracleString s) = Right s
  fromOracle (OracleClob s)   = Right s
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected String but got " ++ show value)
        "FromOracle String"
        False

public export
implementation FromOracle ByteString where
  fromOracle (OracleBlob b) = Right b
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected ByteString but got " ++ show value)
        "FromOracle ByteString"
        False

public export
implementation FromOracle Double where
  fromOracle (OracleNumber n) = Right n
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected NUMBER but got " ++ show value)
        "FromOracle Double"
        False

public export
implementation FromOracle Bool where
  fromOracle (OracleBool b) = Right b
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected BOOLEAN but got " ++ show value)
        "FromOracle Bool"
        False

public export
implementation FromOracle OracleTimestamp where
  fromOracle (OracleTimestamp ts) = Right ts
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected TIMESTAMP but got " ++ show value)
        "FromOracle OracleTimestamp"
        False

public export
implementation FromOracle OracleTimestampTZ where
  fromOracle (OracleTimestampTZ ts) = Right ts
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected TIMESTAMP WITH TIME ZONE but got " ++ show value)
        "FromOracle OracleTimestampTZ"
        False

public export
implementation FromOracle OracleIntervalYM where
  fromOracle (OracleIntervalYM iv) = Right iv
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected INTERVAL YEAR TO MONTH but got " ++ show value)
        "FromOracle OracleIntervalYM"
        False

public export
implementation FromOracle OracleIntervalDS where
  fromOracle (OracleIntervalDS iv) = Right iv
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected INTERVAL DAY TO SECOND but got " ++ show value)
        "FromOracle OracleIntervalDS"
        False

public export
record PersonRow where
  constructor MkPersonRow
  name            : String
  age             : Double
  salary          : Double
  active          : Bool
  notes           : String
  hiretimestamp   : OracleTimestamp
  meetingtimetz   : OracleTimestampTZ
  vacationlength  : OracleIntervalYM
  uptime          : OracleIntervalDS

%runElab derive "PersonRow" [Eq,Ord,Show]

public export
implementation FromRow PersonRow where
  fromRow
    [ name
    , age
    , salary
    , active
    , notes
    , hire
    , meeting
    , vacation
    , uptime
    ]         = do
      name'     <- fromOracle name
      age'      <- fromOracle age
      salary'   <- fromOracle salary
      active'   <- fromOracle active
      notes'    <- fromOracle notes
      hire'     <- fromOracle hire
      meeting'  <- fromOracle meeting
      vacation' <- fromOracle vacation
      uptime'   <- fromOracle uptime
      pure $
        MkPersonRow
          name'
          age'
          salary'
          active'
          notes'
          hire'
          meeting'
          vacation'
          uptime'
  fromRow row =
      Left $
        MkOracleError
          (-1)
          ("Unexpected PERSON row: " ++ show row)
          "PersonRow.fromRow"
          False

public export
implementation ToRow PersonRow where
  toRow person =
    [ MkBindParameter
        ":name"
        (OracleString person.name)
    , MkBindParameter
        ":age"
        (OracleNumber person.age)
    , MkBindParameter
        ":salary"
        (OracleNumber person.salary)
    , MkBindParameter
        ":active"
        (OracleBool person.active)
    , MkBindParameter
        ":notes"
        (OracleClob person.notes)
    , MkBindParameter
        ":hire_timestamp"
        (OracleTimestamp person.hiretimestamp)
    , MkBindParameter
        ":meeting_time_tz"
        (OracleTimestampTZ person.meetingtimetz)
    , MkBindParameter
        ":vacation_length"
        (OracleIntervalYM person.vacationlength)
    , MkBindParameter
        ":uptime"
        (OracleIntervalDS person.uptime)
    ]

public export
record BlobsRow where
  constructor MkBlobsRow
  payload : ByteString

%runElab derive "BlobsRow" [Eq,Ord,Show]

public export
implementation FromRow BlobsRow where
  fromRow [payload] = do
    payload' <- fromOracle payload
    pure (MkBlobsRow payload')
  fromRow row       =
    Left $
      MkOracleError
        (-1)
        ("Unexpected BLOB row: " ++ show row)
        "BlobsRow.fromRow"
        False

public export
implementation ToRow BlobsRow where
  toRow blob =
    [ MkBindParameter
        ":payload"
        (OracleBlob blob.payload)
    ]
