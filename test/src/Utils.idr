module Utils

import System

||| Execute an Oracle operation while ignoring ORA-00955 ("name is already used by an existing object").
|||
||| Oracle automatically commits DDL statements.
|||
||| During integration testing it is convenient to make schema creation idempotent so that repeated executions do not fail simply because an object already exists.
|||
||| Any Oracle error other than ORA-00955 is propagated unchanged.
|||
||| This helper is intended for use by `installSchema`.
|||
export
ignoreAlreadyExists : IO (Either OracleError ()) -> IO (Either OracleError ())
ignoreAlreadyExists action = do
  result <- action
  case result of
    Right () =>
      pure (Right ())
    Left err =>
      case err.code == 955 of
        True  =>
          pure (Right ())
        False =>
           pure (Left err)

||| Install the database schema required by the integration test suite.
|||
||| This function creates all tables, indexes and sequences used by the tests.
|||
||| Existing objects are ignored so that the schema may be installed repeatedly without requiring manual cleanup between runs.
|||
||| Oracle automatically commits DDL statements, so no explicit transaction is required.
|||
export
installSchema : Connection -> IO (Either OracleError ())
installSchema conn =
  ignoreAlreadyExists
    ( execute_ conn """
                    CREATE TABLE people (
                        id         NUMBER PRIMARY KEY,
                        first_name VARCHAR2(100) NOT NULL,
                        last_name  VARCHAR2(100) NOT NULL,
                        age        NUMBER,
                        active     NUMBER(1) DEFAULT 1
                    )
                    """
    )
    >>== \_ =>
  ignoreAlreadyExists
    ( execute_ conn """
                    CREATE SEQUENCE people_seq
                        START WITH 1
                        INCREMENT BY 1
                        NOCACHE
                    """
    )
    >>== \_ =>
  ignoreAlreadyExists
    ( execute_ conn """
                    CREATE INDEX people_last_name_idx
                    ON people(last_name)
                    """
    )
    >>== \_ =>
  ignoreAlreadyExists
    ( execute_ conn """
                    CREATE TABLE blobs (
                        id          NUMBER PRIMARY KEY,
                        description VARCHAR2(100),
                        blob_value  BLOB,
                        clob_value  CLOB
                    )
                    """
    )
    >>== \_ =>
  ignoreAlreadyExists
    ( execute_ conn """
                    CREATE SEQUENCE blobs_seq
                        START WITH 1
                        INCREMENT BY 1
                        NOCACHE
                    """
    )

||| Remove all rows from every integration test table.
|||
||| This function preserves the database schema while deleting all test data created by previous tests.
|||
||| The sequence values are intentionally left unchanged since tests should not rely on specific generated identifiers.
|||
export
clearTables : Connection -> IO (Either OracleError ())
clearTables conn =
  execute_ conn "DELETE FROM blobs"
    >>== \_ =>
  execute_ conn "DELETE FROM people"

||| Populate the PEOPLE table with the standard integration test fixture.
|||
||| Two rows are inserted:
||| - Alice
||| - Bob
|||
||| Primary keys are generated using PEOPLE_SEQ.NEXTVAL.
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
        notes
    )
    VALUES
    (
        people_seq.NEXTVAL,
        :name,
        :age,
        :salary,
        :active,
        CURRENT_TIMESTAMP,
        :notes
    )
    """
    [ MkBindParameter ":name"   (OracleString "Alice")
    , MkBindParameter ":age"    (OracleInt 30)
    , MkBindParameter ":salary" (OracleInt 90000)
    , MkBindParameter ":active" (OracleBool True)
    , MkBindParameter ":notes"  (OracleClob "Alice Notes")
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
        notes
    )
    VALUES
    (
        people_seq.NEXTVAL,
        :name,
        :age,
        :salary,
        :active,
        CURRENT_TIMESTAMP,
        :notes
    )
    """
    [ MkBindParameter ":name"   (OracleString "Bob")
    , MkBindParameter ":age"    (OracleInt 42)
    , MkBindParameter ":salary" (OracleInt 120000)
    , MkBindParameter ":active" (OracleBool False)
    , MkBindParameter ":notes"  (OracleClob "Bob Notes")
    ]

||| Populate the BLOBS table with the standard integration test fixture.
|||
||| A single BLOB row is inserted.
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
        people_seq.NEXTVAL,
        :payload
    )
    """
    [ MkBindParameter
        ":payload"
        (OracleBlob (fromString "Hello from Oracle BLOB"))
    ]

||| Execute an integration test against the test database.
|||
||| A connection is automatically established and closed.
|||
export
withTestConnection : (Connection -> IO a) -> IO a
withTestConnection action = do
  conn <- connect testConnectInfo >>= die ""
  result <- action conn
  disconnect conn
  pure result

||| Restore the integration database to its standard fixture.
|||
||| Existing rows are removed before the default PEOPLE and BLOBS fixtures are recreated.
|||
||| This function is intended to be called before each integration test (or test group).
|||
export
resetDatabase : IO ()
resetDatabase =
  withTestConnection $ \conn => do
    result <- clearTables conn
      >>== \_ =>
         seedPeople conn
      >>== \_ =>
         seedBlobs conn
      >>== \_ =>
         commit conn
    case result of
      Left err =>
        die (show err)
      Right () =>
        pure ()
