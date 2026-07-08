module TypedEncodingDecodingTests

import Data.ByteString
import Oracle
import Oracle.Types.DateTime

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
          "Person.fromRow"
          False

{-
implementation FromRow PersonRow where
  fromRow
    [ OracleString name
    , OracleNumber age
    , OracleNumber salary
    , OracleBool active
    , OracleClob notes
    , OracleTimestamp hire
    , OracleTimestampTZ meeting
    , OracleIntervalYM vacation
    , OracleIntervalDS uptime
    ]         =
      Right $
        MkPersonRow
          name
          age
          salary
          active
          notes
          hire
          meeting
          vacation
          uptime
  fromRow row =
      Left $
        MkOracleError
          (-1)
          ("Unexpected PERSON row: " ++ show row)
          "PersonRow.fromRow"
          False
-}

record BlobRow where
  constructor MkBlobRow
  payload : ByteString

implementation FromRow BlobRow where
  fromRow [payload] = do
    payload' <- fromOracle payload
    pure (MkBlobRow payload')
  {-
  fromRow [OracleBlob bytes] =
    Right (MkBlobRow bytes)
  -}
  fromRow row       =
    Left $
      MkOracleError
        (-1)
        ("Unexpected BLOB row: " ++ show row)
        "BlobRow.fromRow"
        False

export covering
test_QueryTypedPeople : Connection -> IO (Either OracleError ())
test_QueryTypedPeople conn = do
  result <-
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
    Right
      [ MkPerson "Alice" 30 90000 True "Alice Notes"
          (MkOracleTimestamp 2022 5 10 9 15 30 123456789)
          (MkOracleTimestampTZ 2025 7 1 10 45 30 987654321 (-5) 0)
          (MkOracleIntervalYM 2 6)
          (MkOracleIntervalDS 12 8 15 42 555000000)
      , MkPerson "Bob" 42 120000 False "Bob Notes"
          (MkOracleTimestamp 2015 1 8 16 45 1 42)
          (MkOracleTimestampTZ 2024 12 31 23 59 59 999999999 1 30)
          (MkOracleIntervalYM 15 3)
          (MkOracleIntervalDS 365 23 59 59 999999999)
      ]        =>
          pure (Right ())
    Right rows =>
      die "Unexpected decoded people."
