module Oracle.Migration.Runner

import Data.List
import Oracle
import Oracle.Types.Migration

%default total

||| Name of the table used to persist migration history.
|||
export
migrationtable : String
migrationtable = "idris_oracle_migrations"

||| Create the migration history table if it does not already exist.
|||
||| The migration table is owned by the application database schema and is managed entirely by the migration API.
|||
createMigrationTable : Connection -> IO (Either OracleError ())
createMigrationTable conn = do
  result <- execute_
    conn
    """
    CREATE TABLE __idris_migrations (
        version      NUMBER PRIMARY KEY,
        name         VARCHAR2(255) NOT NULL,
        applied_at   TIMESTAMP NOT NULL
    )
    """
    []
  case result of
    Right () =>
      pure (Right ())
    Left err =>
      -- ORA-00955 means the object already exists. Since the migration table
      -- is fixed and owned by this library, an existing table is acceptable.
      case err.code == 955 of
        True  =>
          pure (Right ())
        False =>
          pure (Left err)

||| Retrieve all migrations that have already been applied.
|||
||| Results are ordered by migration version.
|||
export covering
listAppliedMigrations : Connection -> IO (Either OracleError (List MigrationInfo))
listAppliedMigrations conn = do
  result <- queryRaw
    conn
    """
    SELECT
        version,
        name,
        TO_CHAR(
            applied_at,
            'YYYY-MM-DD"T"HH24:MI:SS.FF9'
        )
    FROM __idris_migrations
    ORDER BY version
    """
    []
  case result of
    Left err   =>
      pure (Left err)
    Right rows =>
      decodeRows rows
  where
    decodeRow : List OracleValue -> Either OracleError MigrationInfo
    decodeRow [ OracleNumber version
              , OracleString name
              , OracleString appliedAt
              ]   =
      Right $
        MkMigrationInfo
          (cast version)
          name
          appliedAt
    decodeRow row =
      Left $
        MkOracleError
          (-1)
          ("Invalid migration history row: " ++ show row)
          "Oracle.Migration.Runner.listAppliedMigrations"
          False
    decodeRows : List (List OracleValue) -> IO (Either OracleError (List MigrationInfo))
    decodeRows []            =
      pure (Right [])
    decodeRows (row :: rows) =
      case decodeRow row of
        Left err   =>
          pure (Left err)
        Right info => do
          rest <- decodeRows rows
          case rest of
            Left err    =>
              pure (Left err)
            Right infos =>
              pure (Right (info :: infos))

||| Return migrations that have been defined by the application but have not yet been applied.
|||
export covering
pendingMigrations : Connection -> List Migration -> IO (Either OracleError (List Migration))
pendingMigrations conn migrations = do
  result <- listAppliedMigrations conn
  case result of
    Left err      =>
      pure (Left err)
    Right applied =>
      pure $
        Right $
          filter
            (\migration => not (isMigrationApplied migration applied))
            (sortBy compareMigrationVersion migrations)
  where
    compareMigrationVersion : Migration -> Migration -> Ordering
    compareMigrationVersion a b =
      compare (migrationversion a) (migrationversion b)

||| Return the current migration status.
|||
||| `MigrationPending` indicates a migration exists in the supplied application migration set but has not been applied.
|||
||| `MigrationApplied` indicates both the migration definition and its persisted migration record exist.
|||
||| `MigrationMissing` indicates a migration was previously applied but its definition is no longer present in the supplied migration set.
|||
export covering
migrationStatus : Connection -> List Migration -> IO (Either OracleError (List MigrationStatus))
migrationStatus conn migrations = do
  result <- listAppliedMigrations conn
  case result of
    Left err      =>
      pure (Left err)
    Right applied => do
      let migrationstatuses =
            map (\migration =>
                  case findApplied migration applied of
                    Nothing   =>
                      MigrationPending migration
                    Just info =>
                      MigrationApplied migration info
                )
              (sortBy compareMigrationVersion migrations)
      let missingstatuses   =
            map
              MigrationMissing
              ( filter
                  (\info => not (containsVersion info migrations))
                   applied
              )
      pure $
        Right $
          migrationstatuses ++ missingstatuses
  where
    compareMigrationVersion : Migration -> Migration -> Ordering
    compareMigrationVersion a b =
      compare (migrationversion a) (migrationversion b)
    findApplied : Migration -> List MigrationInfo -> Maybe MigrationInfo
    findApplied migration []                                =
      Nothing
    findApplied migration (migrationinfo :: migrationinfos) =
      case sameMigrationVersion migration migrationinfo of
        True  =>
          Just migrationinfo
        False =>
          findApplied migration migrationinfos
    containsVersion : MigrationInfo -> List Migration -> Bool
    containsVersion migrationinfo []               =
      False
    containsVersion migrationinfo (migration :: migrations) =
      case migrationinfoversion migrationinfo == migrationversion migration of
        True =>
          True
        False =>
          containsVersion migrationinfo migrations

||| Record a successfully applied migration.
|||
recordMigration : Connection -> Migration -> IO (Either OracleError ())
recordMigration conn migration =
  execute_
    conn
    """
    INSERT INTO __idris_migrations
    (
        version,
        name,
        applied_at
    )
    VALUES
    (
        :version,
        :name,
        CURRENT_TIMESTAMP
    )
    """
    [ MkBindParameter
        ":version"
        (OracleNumber (cast (migrationversion migration)))
    , MkBindParameter
        ":name"
        (OracleString (migrationname migration))
    ]

||| Remove a migration from the migration history.
|||
removeMigrationRecord : Connection -> Migration -> IO (Either OracleError ())
removeMigrationRecord conn migration =
  execute_
    conn
    """
    DELETE FROM __idris_migrations
    WHERE version = :version
    """
    [ MkBindParameter
        ":version"
        (OracleNumber (cast (migrationversion migration)))
    ]

||| Execute all pending migrations in ascending version order.
|||
||| Each migration is applied by invoking its `up` action.
|||
||| The migration is recorded in the migration history only after `up` succeeds.
|||
||| The operation commits after each successfully applied migration.
|||
||| This ensures that the migration history cannot claim that a migration succeeded when its database changes were rolled back.
|||
export covering
runMigrations : Connection -> List Migration -> IO (Either OracleError ())
runMigrations conn migrations = do
  tableresult <- createMigrationTable conn
  case tableresult of
    Left err =>
      pure (Left err)
    Right () => do
      pendingresult <- pendingMigrations conn migrations
      case pendingresult of
        Left err      =>
          pure (Left err)
        Right pending =>
          runPending conn pending
  where
    runPending : Connection -> List Migration -> IO (Either OracleError ())
    runPending _    []                        =
      pure (Right ())
    runPending conn (migration :: migrations) = do
      result <- (migrationup migration) conn
      case result of
        Left err =>
          pure (Left err)
        Right () => do
          recordresult <- recordMigration conn migration
          case recordresult of
            Left err =>
              pure (Left err)
            Right () => do
              commitresult <- commit conn
              case commitresult of
                Left err =>
                  pure (Left err)
                Right () =>
                  runPending conn migrations

||| Roll back the most recently applied migration.
|||
||| The supplied migration list is used to find the executable rollback action corresponding to the most recently applied migration.
|||
||| Fails if:
||| * No migrations have been applied.
||| * The latest applied migration has no corresponding definition in the supplied migration list.
|||
||| The migration history record is removed only after the rollback action succeeds.
|||
export covering
rollbackMigration : Connection -> List Migration -> IO (Either OracleError ())
rollbackMigration conn migrations = do
  tableresult <- createMigrationTable conn
  case tableresult of
    Left err =>
      pure (Left err)
    Right () => do
      appliedresult <- listAppliedMigrations conn
      case appliedresult of
        Left err =>
          pure (Left err)
        Right [] =>
          pure $
            Left $
              MkOracleError
                (-1)
                "No migrations have been applied"
                "Oracle.Migration.Runner.rollbackMigration"
                False
        Right applied =>
          case latestMigration applied of
            Nothing =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    "Unable to determine latest migration"
                    "Oracle.Migration.Runner.rollbackMigration"
                    False
            Just latest        =>
              case findMigration latest migrations of
                Nothing =>
                  pure $
                    Left $
                      MkOracleError
                        (-1)
                        ( "Migration definition not found for applied version "
                          ++ show (migrationinfoversion latest)
                        )
                        "Oracle.Migration.Runner.rollbackMigration"
                        False
                Just migration =>
                  rollback conn migration
  where
    latestMigration : List MigrationInfo -> Maybe MigrationInfo
    latestMigration []              =
      Nothing
    latestMigration (info :: infos) =
      Just $
        foldl
          (\current, candidate =>
            case migrationinfoversion candidate > migrationinfoversion current of
              True  =>
                candidate
              False =>
                current
          )
          info
          infos
    findMigration : MigrationInfo -> List Migration -> Maybe Migration
    findMigration _ []                                    =
      Nothing
    findMigration migrationinfo (migration :: migrations) =
      case migrationinfoversion migrationinfo == migrationversion migration of
        True  =>
          Just migration
        False =>
          findMigration migrationinfo migrations
    rollback : Connection -> Migration -> IO (Either OracleError ())
    rollback conn migration = do
      result <- (migrationdown migration) conn
      case result of
        Left err =>
          pure (Left err)
        Right () => do
          removeResult <- removeMigrationRecord conn migration
          case removeResult of
            Left err =>
              pure (Left err)
            Right () =>
              commit conn
