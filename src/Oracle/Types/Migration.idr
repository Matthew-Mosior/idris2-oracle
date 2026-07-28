module Oracle.Types.Migration

import Data.List
import Oracle.Types.Error

%default total

||| A database migration.
|||
||| Migrations are defined entirely through the Idris API. There are no
||| migration files or filesystem-based migration discovery mechanisms.
|||
||| `version` must uniquely identify the migration within a migration set.
||| Migrations are normally applied in ascending version order.
|||
||| `name` provides a human-readable description of the migration.
|||
||| `up` applies the migration.
|||
||| `down` reverses the migration.
|||
public export
record Migration where
  constructor MkMigration
  migrationversion : Int
  migrationname    : String
  migrationup      : IO (Either OracleError ())
  migrationdown    : IO (Either OracleError ())

||| Information about a migration that has been recorded in the database.
|||
||| This represents the persisted migration history rather than the executable migration definition itself.
|||
public export
record MigrationInfo where
  constructor MkMigrationInfo
  migrationinfoversion   : Int
  migrationinfoname      : String
  migrationinfoappliedAt : String

||| The status of a migration relative to the supplied migration definitions and the migration history persisted in Oracle.
|||
public export
data MigrationStatus
  = MigrationPending Migration
  | MigrationApplied Migration MigrationInfo
  | MigrationMissing MigrationInfo

||| Determine whether a migration version matches a persisted migration.
|||
export
sameMigrationVersion : Migration -> MigrationInfo -> Bool
sameMigrationVersion migration migrationinfo =
  migrationversion migration == migrationinfoversion migrationinfo

||| Determine whether a migration has already been applied.
|||
export
isMigrationApplied : Migration -> List MigrationInfo -> Bool
isMigrationApplied migration migrationinfos =
  any (sameMigrationVersion migration) migrationinfos
