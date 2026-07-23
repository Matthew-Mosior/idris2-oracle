module TransactionTests

import Data.ByteString
import Oracle
import Oracle.Types.DateTime
import Utils

||| Verify that COMMIT permanently persists changes.
|||
export covering
test_CommitPersistsChanges : Connection -> IO (Either OracleError ())
test_CommitPersistsChanges conn = do
  result <-
    clearTables conn >>==
    \_ =>
      execute_
        conn
        """
        INSERT INTO people
        (
            id,
            name,
            age
        )
        VALUES
        (
            people_seq.NEXTVAL,
            'Alice',
            30
        )
        """
        []
      >>== \_ =>
      commit conn
      >>== \_ =>
      query
        conn
        """
        SELECT COUNT(*)
        FROM people
        """
        []
  case result of
    Right [[OracleNumber 1]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: "++ show rows)
                        "TransactionTests.test_CommitPersistChanges"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_CommitPersistChanges"
                        False

||| Verify that ROLLBACK discards uncommitted inserts.
|||
export covering
test_RollbackDiscardsChanges : Connection -> IO (Either OracleError ())
test_RollbackDiscardsChanges conn = do
  result <-
    clearTables conn >>==
    \_ =>
      execute_
        conn
        """
        INSERT INTO people
        (
            id,
            name,
            age
        )
        VALUES
        (
            people_seq.NEXTVAL,
            'Alice',
            30
        )
        """
        []
      >>== \_ =>
      rollback conn
      >>== \_ =>
      query
        conn
        """
        SELECT COUNT(*)
        FROM people
        """
        []
  case result of
    Right [[OracleNumber 0]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: "++ show rows)
                        "TransactionTests.test_RollbackDiscardsChanges"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_RollbackDiscardsChanges"
                        False

||| Verify that committed UPDATE statements persist.
|||
export covering
test_CommitPersistsUpdate : Connection -> IO (Either OracleError ())
test_CommitPersistsUpdate conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      execute_
        conn
        """
        UPDATE people
        SET age = 99
        WHERE name = 'Alice'
        """
        []
      >>== \_ =>
      commit conn
      >>== \_ =>
      query
        conn
        """
        SELECT age
        FROM people
        WHERE name='Alice'
        """
        []
  case result of
    Right [[OracleNumber 99]] =>
      pure (Right ())
    Right rows                =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_CommitPersistsUpdate"
                        False
    Left err                  =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_CommitPersistsUpdate"
                        False

||| Verify that ROLLBACK restores previous values after UPDATE.
|||
export covering
test_RollbackDiscardsUpdate : Connection -> IO (Either OracleError ())
test_RollbackDiscardsUpdate conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      execute_
        conn
        """
        UPDATE people
        SET age = 99
        WHERE name='Alice'
        """
        []
      >>== \_ =>
      rollback conn
      >>== \_ =>
      query
        conn
        """
        SELECT age
        FROM people
        WHERE name='Alice'
        """
        []
  case result of
    Right [[OracleNumber 30]] =>
      pure (Right ())
    Right rows                =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_RollbackDiscardsUpdate"
                        False
    Left err                  =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_RollbackDiscardsUpdate"
                        False

||| Verify that committed DELETE statements persist.
|||
export covering
test_CommitPersistsDelete : Connection -> IO (Either OracleError ())
test_CommitPersistsDelete conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      execute_
        conn
        "DELETE FROM people WHERE name='Alice'"
        []
      >>== \_ =>
      commit conn
      >>== \_ =>
      query
        conn
        "SELECT COUNT(*) FROM people"
        []
  case result of
    Right [[OracleNumber 1]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_CommitPersistsDelete"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_CommitPersistsDelete"
                        False

||| Verify that deleted rows return after ROLLBACK.
|||
export covering
test_RollbackRestoresDelete : Connection -> IO (Either OracleError ())
test_RollbackRestoresDelete conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      execute_
        conn
        "DELETE FROM people WHERE name='Alice'"
        []
      >>== \_ =>
      rollback conn
      >>== \_ =>
      query
        conn
        "SELECT COUNT(*) FROM people"
        []
  case result of
    Right [[OracleNumber 2]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_RollbackRestoresDelete"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_RollbackRestoresDelete"
                        False

||| Verify that multiple DML statements commit together.
|||
export covering
test_CommitMultipleStatements : Connection -> IO (Either OracleError ())
test_CommitMultipleStatements conn = do
  result <-
    clearTables conn >>==
    \_ =>
      execute_
        conn
        """
        INSERT INTO people(id,name,age)
        VALUES(people_seq.NEXTVAL,'Alice',30)
        """
        []
      >>== \_ =>
      execute_
        conn
        """
        INSERT INTO people(id,name,age)
        VALUES(people_seq.NEXTVAL,'Bob',42)
        """
        []
      >>== \_ =>
      commit conn
      >>== \_ =>
      query
        conn
        "SELECT COUNT(*) FROM people"
        []
  case result of
    Right [[OracleNumber 2]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_CommitMultipleStatements"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_CommitMultipleStatements"
                        False

||| Verify that multiple DML statements are rolled back together.
|||
export covering
test_RollbackMultipleStatements : Connection -> IO (Either OracleError ())
test_RollbackMultipleStatements conn = do
  result <-
    clearTables conn >>==
    \_ =>
      execute_
        conn
        """
        INSERT INTO people(id,name,age)
        VALUES(people_seq.NEXTVAL,'Alice',30)
        """
        []
      >>== \_ =>
      execute_
        conn
        """
        INSERT INTO people(id,name,age)
        VALUES(people_seq.NEXTVAL,'Bob',42)
        """
        []
      >>== \_ =>
      rollback conn
      >>== \_ =>
      query
        conn
        "SELECT COUNT(*) FROM people"
        []
  case result of
    Right [[OracleNumber 0]] =>
      pure (Right ())
    Right rows               =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected rows: " ++ show rows)
                        "TransactionTests.test_RollbackMultipleStatements"
                        False
    Left err                 =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TransactionTests.test_RollbackMultipleStatements"
                        False
