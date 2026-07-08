module TypedEncodingDecodingTests

import Data.ByteString
import Derive.Prelude
import Oracle
import Oracle.Types.DateTime
import System
import Utils

%language ElabReflection

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

implementation FromOracle ByteString where
  fromOracle (OracleBlob b) = Right b
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected ByteString but got " ++ show value)
        "FromOracle ByteString"
        False

implementation FromOracle Double where
  fromOracle (OracleNumber n) = Right n
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected NUMBER but got " ++ show value)
        "FromOracle Double"
        False

implementation FromOracle Bool where
  fromOracle (OracleBool b) = Right b
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected BOOLEAN but got " ++ show value)
        "FromOracle Bool"
        False

implementation FromOracle OracleTimestamp where
  fromOracle (OracleTimestamp ts) = Right ts
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected TIMESTAMP but got " ++ show value)
        "FromOracle OracleTimestamp"
        False

implementation FromOracle OracleTimestampTZ where
  fromOracle (OracleTimestampTZ ts) = Right ts
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected TIMESTAMP WITH TIME ZONE but got " ++ show value)
        "FromOracle OracleTimestampTZ"
        False

implementation FromOracle OracleIntervalYM where
  fromOracle (OracleIntervalYM iv) = Right iv
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected INTERVAL YEAR TO MONTH but got " ++ show value)
        "FromOracle OracleIntervalYM"
        False

implementation FromOracle OracleIntervalDS where
  fromOracle (OracleIntervalDS iv) = Right iv
  fromOracle value =
    Left $
      MkOracleError
        (-1)
        ("Expected INTERVAL DAY TO SECOND but got " ++ show value)
        "FromOracle OracleIntervalDS"
        False

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

record BlobRow where
  constructor MkBlobRow
  payload : ByteString

%runElab derive "BlobRow" [Eq,Ord,Show]

implementation FromRow BlobRow where
  fromRow [payload] = do
    payload' <- fromOracle payload
    pure (MkBlobRow payload')
  fromRow row       =
    Left $
      MkOracleError
        (-1)
        ("Unexpected BLOB row: " ++ show row)
        "BlobRow.fromRow"
        False

implementation ToRow BlobRow where
  toRow blob =
    [ MkBindParameter
        ":payload"
        (OracleBlob blob.payload)
    ]

export covering
test_QueryTypedPeople : Connection -> IO (Either OracleError ())
test_QueryTypedPeople conn = do
  result : Either OracleError (List PersonRow) <-
    resetDatabase conn >>==
    \_ =>
      query_
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        ORDER BY id
        """
        []
  case result of
    Left err   =>
      die (show err)
    Right rows =>
      case rows of
        [ MkPersonRow "Alice"
                      30
                      90000
                      True
                      "Alice Notes"
                      (MkOracleTimestamp 2022 5 10 9 15 30 123457000)
                      (MkOracleTimestampTZ 2025 7 1 10 45 30 987654000 (-5) 0)
                      (MkOracleIntervalYM 2 6)
                      (MkOracleIntervalDS 12 8 15 42 555000000)
        , MkPersonRow "Bob"
                      42
                      120000
                      False
                      "Bob Notes"
                      (MkOracleTimestamp 2015 1 8 16 45 1 0)
                      (MkOracleTimestampTZ 2025 1 1 0 0 0 0 (-5) 0)
                      (MkOracleIntervalYM 15 3)
                      (MkOracleIntervalDS 365 23 59 59 999999999)
        ]     =>
          pure (Right ())
        rows' =>
          die "Unexpected decoded people."
