module MigrationTests

import Oracle
import Oracle.Migration

import ConnectInfoTest
import Utils

||| First test migration.
|||
||| Creates the MIGRATION_PEOPLE table.
|||
migration001 : Connection -> Migration
migration001 conn =
  MkMigration
    1
    "Create migration_people table"
    ( \conn =>
       execute_
         conn
         """
         CREATE TABLE migration_people (
         id   NUMBER PRIMARY KEY,
         name VARCHAR2(100) NOT NULL
         )
         """
         []
    )
    (\conn =>
      execute_
        conn
        "DROP TABLE migration_people CASCADE CONSTRAINTS"
        []
    )

||| Second test migration.
|||
||| Adds an EMAIL column to the MIGRATION_PEOPLE table.
|||
migration002 : Connection -> Migration
migration002 conn =
  MkMigration
    2
    "Add email to migration_people"
    (\conn =>
      execute_
        conn
        """
        ALTER TABLE migration_people
        ADD email VARCHAR2(255)
        """
        []
    )
    (\conn =>
      execute_
        conn
        """
        ALTER TABLE migration_people
        DROP COLUMN email
        """
        []
    )

||| All migrations used by the migration integration tests.
|||
testMigrations : Connection -> List Migration
testMigrations conn =
  [ migration001 conn
  , migration002 conn
  ]

||| Execute an operation and convert an Oracle error into a failed test.
|||
expectRight : Show e => Either e a -> IO (Either e a)
expectRight result =
  case result of
    Left err =>
      pure (Left err)
    Right value =>
      pure (Right value)

||| Return whether a migration with the given version is present in the
||| migration information list.
|||
hasMigrationVersion : Nat -> List MigrationInfo -> Bool
hasMigrationVersion version infos =
  any (\info => info.migrationinfoversion == cast version) infos

||| Return whether a migration with the given version is pending.
|||
hasPendingVersion : Nat -> List Migration -> Bool
hasPendingVersion version migrations =
  any (\migration => migration.migrationversion == cast version) migrations

||| Verify that the migration system starts with no applied migrations.
|||
export
test_MigrationInitialState : Connection -> IO (Either OracleError ())
test_MigrationInitialState conn = do
  result <- listAppliedMigrations conn
  case result of
    Left err    =>
      pure (Left err)
    Right infos =>
      case infos of
        [] =>
          pure (Right ())
        _  =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Expected no applied migrations"
                "MigrationTests.test_MigrationInitialState"
                False

||| Verify that both test migrations are initially pending.
|||
export
test_PendingMigrations : Connection -> IO (Either OracleError ())
test_PendingMigrations conn = do
  result <- pendingMigrations conn (testMigrations conn)
  case result of
    Left err      =>
      pure (Left err)
    Right pending =>
      case length pending == 2
        && hasPendingVersion 1 pending
        && hasPendingVersion 2 pending of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Unexpected pending migrations"
                "MigrationTests.test_PendingMigrations"
                False

||| Run all test migrations.
|||
export
test_RunMigrations : Connection -> IO (Either OracleError ())
test_RunMigrations conn =
  runMigrations conn (testMigrations conn)

||| Verify that both migrations have been recorded as applied.
|||
export
test_AppliedMigrations : Connection -> IO (Either OracleError ())
test_AppliedMigrations conn = do
  result <- listAppliedMigrations conn
  case result of
    Left err    =>
      pure (Left err)
    Right infos =>
      case length infos == 2
        && hasMigrationVersion 1 infos
        && hasMigrationVersion 2 infos of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Unexpected applied migrations"
                "MigrationTests.test_AppliedMigrations"
                False

||| Verify the migration status after applying all migrations.
|||
export
test_MigrationStatusApplied : Connection -> IO (Either OracleError ())
test_MigrationStatusApplied conn = do
  result <- migrationStatus conn (testMigrations conn)
  case result of
    Left err =>
      pure (Left err)
    Right _  =>
      pure (Right ())

||| Verify that the PEOPLE table exists after migration 001 and that the
||| EMAIL column exists after migration 002.
|||
export
test_MigrationSchema : Connection -> IO (Either OracleError ())
test_MigrationSchema conn = do
  result <- queryRaw conn
                     """
                     SELECT
                     column_name
                     FROM user_tab_columns
                     WHERE table_name = 'MIGRATION_PEOPLE'
                     ORDER BY column_id
                     """
                     []
  case result of
    Left err =>
      pure (Left err)
    Right rows =>
      case rows of
        [ [OracleString "ID"]
        , [OracleString "NAME"]
        , [OracleString "EMAIL"]
        ] =>
          pure (Right ())
        _ =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Unexpected MIGRATION_PEOPLE schema: " ++ show rows)
                "MigrationTests.test_MigrationSchema"
                False

||| Roll back migration 002.
|||
||| Migration 001 remains applied.
|||
export
test_RollbackMigration002 : Connection -> IO (Either OracleError ())
test_RollbackMigration002 conn =
  rollbackMigration conn [ migration002 conn
                         ]

||| Verify that migration 002 has been rolled back while migration 001
||| remains applied.
|||
export
test_AfterRollback : Connection -> IO (Either OracleError ())
test_AfterRollback conn = do
  result <- listAppliedMigrations conn
  case result of
    Left err    =>
      pure (Left err)
    Right infos =>
      case length infos == 1
        && hasMigrationVersion 1 infos
        && not (hasMigrationVersion 2 infos) of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Unexpected migrations after rollback"
                "MigrationTests.test_AfterRollback"
                False

||| Verify that migration 002's EMAIL column no longer exists after rollback.
|||
export
test_SchemaAfterRollback : Connection -> IO (Either OracleError ())
test_SchemaAfterRollback conn = do
  result <- queryRaw conn
                     """
                     SELECT
                     column_name
                     FROM user_tab_columns
                     WHERE table_name = 'MIGRATION_PEOPLE'
                     ORDER BY column_id
                     """
                     []
  case result of
    Left err   =>
      pure (Left err)
    Right rows =>
      case rows of
        [ [OracleString "ID"]
        , [OracleString "NAME"]
        ] =>
          pure (Right ())
        _ =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Unexpected MIGRATION_PEOPLE schema after rollback: " ++ show rows)
                "MigrationTests.test_SchemaAfterRollback"
                False

||| Verify that migration 002 becomes pending again after rollback.
|||
export
test_PendingAfterRollback : Connection -> IO (Either OracleError ())
test_PendingAfterRollback conn = do
  result <- pendingMigrations conn (testMigrations conn)
  case result of
    Left err      =>
      pure (Left err)
    Right pending =>
      case length pending == 1
        && hasPendingVersion 2 pending of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Unexpected pending migrations after rollback"
                "MigrationTests.test_PendingAfterRollback"
                False

||| Re-run migration 002 after it has been rolled back.
|||
export
test_RerunMigrations : Connection -> IO (Either OracleError ())
test_RerunMigrations conn =
  runMigrations conn (testMigrations conn)

||| Verify that the migration system returns to the fully applied state.
|||
export
test_FinalState : Connection -> IO (Either OracleError ())
test_FinalState conn = do
  result <- listAppliedMigrations conn
  case result of
    Left err    =>
      pure (Left err)
    Right infos =>
      case length infos == 2
        && hasMigrationVersion 1 infos
        && hasMigrationVersion 2 infos of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError
                (-1)
                "Unexpected final migration state"
                "MigrationTests.test_FinalState"
                False
