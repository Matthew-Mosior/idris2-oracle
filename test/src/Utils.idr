module Utils

import ConnectInfoTest
import Data.ByteString
import Oracle
import System

||| Execute an Oracle operation while ignoring errors indicating that the requested schema object does not exist.
|||
||| Ignored errors:
||| * ORA-00942 - table or view does not exist
||| * ORA-02289 - sequence does not exist
||| * ORA-02443 - cannot drop constraint/index; does not exist
|||
export
ignoreMissingObject : IO (Either OracleError ()) -> IO (Either OracleError ())
ignoreMissingObject action = do
  result <- action
  case result of
    Right () =>
      pure (Right ())
    Left err =>
      case err.code == 942 || err.code == 2289 || err.code == 2443 of
        True  =>
          pure (Right ())
        False =>
          pure (Left err)

||| Install the database schema required by the integration test suite.
|||
||| Any existing schema objects are dropped before being recreated so every
||| test run starts from a known schema.
|||
export
installSchema : Connection -> IO (Either OracleError ())
installSchema conn =
  ignoreMissingObject
    (execute_ conn "DROP TABLE blobs CASCADE CONSTRAINTS" [])
  >>== \_ =>
  ignoreMissingObject
    (execute_ conn "DROP TABLE people CASCADE CONSTRAINTS" [])
  >>== \_ =>
  ignoreMissingObject
    (execute_ conn "DROP SEQUENCE blobs_seq" [])
  >>== \_ =>
  ignoreMissingObject
    (execute_ conn "DROP SEQUENCE people_seq" [])
  >>== \_ =>
  execute_
    conn
    """
    CREATE TABLE people (
    id                  NUMBER PRIMARY KEY,
    name                VARCHAR2(100) NOT NULL,
    age                 NUMBER,
    salary              NUMBER,
    active              NUMBER(1) DEFAULT 1,
    created_at          TIMESTAMP,
    notes               CLOB,
    hire_timestamp      TIMESTAMP,
    meeting_time_tz     TIMESTAMP WITH TIME ZONE,
    vacation_length     INTERVAL YEAR(4) TO MONTH,
    uptime              INTERVAL DAY(9) TO SECOND(9)
    )
    """
    []
  >>== \_ =>
  execute_
    conn
    """
    CREATE SEQUENCE people_seq
        START WITH 1
        INCREMENT BY 1
        NOCACHE
    """
    []
  >>== \_ =>
  execute_
    conn
    """
    CREATE INDEX people_name_idx
    ON people(name)
    """
    []
  >>== \_ =>
  execute_
    conn
    """
    CREATE TABLE blobs (
        id       NUMBER PRIMARY KEY,
        payload  BLOB
    )
    """
    []
  >>== \_ =>
  execute_
    conn
    """
    CREATE SEQUENCE blobs_seq
        START WITH 1
        INCREMENT BY 1
        NOCACHE
    """
    []

||| Remove all rows from every integration test table.
|||
export
clearTables : Connection -> IO (Either OracleError ())
clearTables conn =
  execute_ conn "TRUNCATE TABLE blobs" []
    >>== \_ =>
  execute_ conn "TRUNCATE TABLE people" []

||| Populate the PEOPLE table with the standard integration test fixture.
|||
export
seedPeople : Connection -> IO (Either OracleError ())
seedPeople conn =
  execute_
    conn
    """
    INSERT INTO people
    (
        id,
        name,
        age,
        salary,
        active,
        created_at,
        notes,
        hire_timestamp,
        meeting_time_tz,
        vacation_length,
        uptime
    )
    VALUES
    (
        people_seq.NEXTVAL,
        :name,
        :age,
        :salary,
        :active,
        CURRENT_TIMESTAMP,
        :notes,
        :hire_timestamp,
        :meeting_time_tz,
        :vacation_length,
        :uptime
    )
    """
    [ MkBindParameter ":name"   (OracleString "Alice")
    , MkBindParameter ":age"    (OracleInt 30)
    , MkBindParameter ":salary" (OracleInt 90000)
    , MkBindParameter ":active" (OracleBool True)
    , MkBindParameter ":notes"  (OracleClob "Alice Notes")
    , MkBindParameter ":hire_timestamp" ( OracleTimestamp $
                                            MkOracleTimestamp
                                              2022 5 10
                                              9 15 30
                                              123456789
                                        )
    , MkBindParameter ":meeting_time_tz" ( OracleTimestampTZ $
                                             MkOracleTimestampTZ
                                               2025 7 1
                                               10 45 30
                                               987654321
                                               (-5)
                                               0
                                         )
    , MkBindParameter ":vacation_length" ( OracleIntervalYM $
                                             MkOracleIntervalYM
                                               2
                                               6
                                         )
    , MkBindParameter ":uptime" ( OracleIntervalDS $
                                    MkOracleIntervalDS
                                      12
                                      8
                                      15
                                      42
                                      555000000
                                )
    ]
  >>== \_ =>
  execute_
    conn
    """
    INSERT INTO people
    (
        id,
        name,
        age,
        salary,
        active,
        created_at,
        notes,
        hire_timestamp,
        meeting_time_tz,
        vacation_length,
        uptime
    )
    VALUES
    (
        people_seq.NEXTVAL,
        :name,
        :age,
        :salary,
        :active,
        CURRENT_TIMESTAMP,
        :notes,
        :hire_timestamp,
        :meeting_time_tz,
        :vacation_length,
        :uptime
    )
    """
    [ MkBindParameter ":name"   (OracleString "Bob")
    , MkBindParameter ":age"    (OracleInt 42)
    , MkBindParameter ":salary" (OracleInt 120000)
    , MkBindParameter ":active" (OracleBool False)
    , MkBindParameter ":notes"  (OracleClob "Bob Notes")
    , MkBindParameter ":hire_timestamp" ( OracleTimestamp $
                                            MkOracleTimestamp
                                              2015 1 8
                                              16 45 1
                                              42
                                        )
    , MkBindParameter ":meeting_time_tz" ( OracleTimestampTZ $
                                             MkOracleTimestampTZ
                                               2024 12 31
                                               23 59 59
                                               999999999
                                               1
                                               30
                                         )
    , MkBindParameter ":vacation_length" ( OracleIntervalYM $
                                             MkOracleIntervalYM
                                               15
                                               3
                                         )
    , MkBindParameter ":uptime" ( OracleIntervalDS $
                                    MkOracleIntervalDS
                                      365
                                      23
                                      59
                                      59
                                      999999999
                                )
    ]

||| Populate the BLOBS table with the standard integration test fixture.
|||
export
seedBlobs : Connection -> IO (Either OracleError ())
seedBlobs conn =
  execute_
    conn
    """
    INSERT INTO blobs
    (
        id,
        payload
    )
    VALUES
    (
        blobs_seq.NEXTVAL,
        :payload
    )
    """
    [ MkBindParameter
        ":payload"
        (OracleBlob (fromString "FF"))
    ]

||| Restore the integration database to its standard fixture.
|||
export
resetDatabase : Connection -> IO (Either OracleError ())
resetDatabase conn =
  clearTables conn
  >>== \_ =>
  seedPeople conn
  >>== \_ =>
  seedBlobs conn
  >>== \_ => do
    c <- commit conn
    case c of
      Left err => do
        putStrLn "error: \{show err}"
        pure (Left err)
      Right _  => do
        rows <- query conn "SELECT COUNT(*) FROM people" []
        putStrLn ("People after seed: " ++ show rows)
        rows' <- query conn "SELECT name FROM people" []
        putStrLn ("People: " ++ show rows')
        rows'' <- query conn "SELECT DUMP(name), LENGTH(name), name FROM people" []
        putStrLn ("Dump from people: " ++ show rows'')
        pure (Right ())
