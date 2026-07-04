module BindTests

import ConnectInfoTest
import Data.ByteString
import Oracle
import Oracle.Types.DateTime
import System

private
runBind : ConnectInfo -> String -> List BindParameter -> IO (Either OracleError ())
runBind cfg sql params =
  withConnection cfg $ \conn =>
    withStatement conn sql $ \stmt => do
      bind stmt params >>==
      \_ => execute stmt

||| Verify that NULL values can be bound successfully.
|||
export
test_BindNull : ConnectInfo -> IO (Either OracleError ())
test_BindNull cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people
      (
          id,name,age,salary,active,
          created_at,notes,
          birth_date,hire_timestamp,meeting_time_tz,login_time_ltz,
          vacation_length,uptime
      )
      VALUES
      (
          people_seq.NEXTVAL,
          'Null',
          NULL,NULL,NULL,
          NULL,NULL,
          NULL,NULL,NULL,NULL,
          NULL,NULL
      )
      """
      []
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify VARCHAR2 binding.
|||
export
test_BindString : ConnectInfo -> IO (Either OracleError ())
test_BindString cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name)
      VALUES(people_seq.NEXTVAL,:name)
      """
      [ MkBindParameter ":name" (OracleString "Alice") ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify NUMBER integer binding.
|||
export
test_BindInt : ConnectInfo -> IO (Either OracleError ())
test_BindInt cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,age)
      VALUES(people_seq.NEXTVAL,'Age',:age)
      """
      [ MkBindParameter ":age" (OracleInt 42) ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify floating-point NUMBER binding.
|||
export
test_BindDouble : ConnectInfo -> IO (Either OracleError ())
test_BindDouble cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,salary)
      VALUES(people_seq.NEXTVAL,'Salary',:salary)
      """
      [ MkBindParameter ":salary" (OracleDouble 12345.67) ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify TRUE boolean binding.
|||
export
test_BindBoolTrue : ConnectInfo -> IO (Either OracleError ())
test_BindBoolTrue cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,active)
      VALUES(people_seq.NEXTVAL,'True',:active)
      """
      [ MkBindParameter ":active" (OracleBool True) ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify FALSE boolean binding.
|||
export
test_BindBoolFalse : ConnectInfo -> IO (Either OracleError ())
test_BindBoolFalse cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,active)
      VALUES(people_seq.NEXTVAL,'False',:active)
      """
      [ MkBindParameter ":active" (OracleBool False) ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify CLOB binding.
|||
export
test_BindClob : ConnectInfo -> IO (Either OracleError ())
test_BindClob cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,notes)
      VALUES(people_seq.NEXTVAL,'Clob',:notes)
      """
      [ MkBindParameter ":notes" (OracleClob "Large text") ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify BLOB binding.
|||
export
test_BindBlob : ConnectInfo -> IO (Either OracleError ())
test_BindBlob cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO blobs(id,payload)
      VALUES(blobs_seq.NEXTVAL,:payload)
      """
      [ MkBindParameter
          ":payload"
          (OracleBlob (fromString "Hello Blob"))
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify DATE binding.
|||
export
test_BindDate : ConnectInfo -> IO (Either OracleError ())
test_BindDate cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,birth_date)
      VALUES(people_seq.NEXTVAL,'Date',:d)
      """
      [ MkBindParameter
          ":d"
          (OracleDate $
            MkOracleDate 1995 7 12 13 14 15)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify TIMESTAMP binding.
|||
export
test_BindTimestamp : ConnectInfo -> IO (Either OracleError ())
test_BindTimestamp cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,hire_timestamp)
      VALUES(people_seq.NEXTVAL,'TS',:ts)
      """
      [ MkBindParameter
          ":ts"
          (OracleTimestamp $
            MkOracleTimestamp
              2025 6 1 12 34 56 123456789)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify TIMESTAMP WITH TIME ZONE binding.
|||
export
test_BindTimestampTZ : ConnectInfo -> IO (Either OracleError ())
test_BindTimestampTZ cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,meeting_time_tz)
      VALUES(people_seq.NEXTVAL,'TZ',:ts)
      """
      [ MkBindParameter
          ":ts"
          (OracleTimestampTZ $
            MkOracleTimestampTZ
              2025 6 1
              12 34 56
              123456789
              (-5)
              0)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify TIMESTAMP WITH LOCAL TIME ZONE binding.
|||
export
test_BindTimestampLTZ : ConnectInfo -> IO (Either OracleError ())
test_BindTimestampLTZ cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,login_time_ltz)
      VALUES(people_seq.NEXTVAL,'LTZ',:ts)
      """
      [ MkBindParameter
          ":ts"
          (OracleTimestampLTZ $
            MkOracleTimestamp
              2025 6 1
              12 34 56
              987654321)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify INTERVAL YEAR TO MONTH binding.
|||
export
test_BindIntervalYM : ConnectInfo -> IO (Either OracleError ())
test_BindIntervalYM cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,vacation_length)
      VALUES(people_seq.NEXTVAL,'YM',:v)
      """
      [ MkBindParameter
          ":v"
          (OracleIntervalYM $
            MkOracleIntervalYM 10 6)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify INTERVAL DAY TO SECOND binding.
|||
export
test_BindIntervalDS : ConnectInfo -> IO (Either OracleError ())
test_BindIntervalDS cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people(id,name,uptime)
      VALUES(people_seq.NEXTVAL,'DS',:v)
      """
      [ MkBindParameter
          ":v"
          (OracleIntervalDS $
            MkOracleIntervalDS
              5 12 30 45 123456789)
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify that many parameters can be bound in a single statement.
|||
export
test_BindManyParameters : ConnectInfo -> IO (Either OracleError ())
test_BindManyParameters cfg = do
  result <-
    runBind cfg
      """
      INSERT INTO people
      (
          id,name,age,salary,active,notes
      )
      VALUES
      (
          people_seq.NEXTVAL,
          :name,
          :age,
          :salary,
          :active,
          :notes
      )
      """
      [ MkBindParameter ":name" (OracleString "Many")
      , MkBindParameter ":age" (OracleInt 33)
      , MkBindParameter ":salary" (OracleDouble 1000.5)
      , MkBindParameter ":active" (OracleBool True)
      , MkBindParameter ":notes" (OracleClob "Hello")
      ]
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify that the same prepared statement may be rebound and executed multiple times.
|||
export
test_RebindParameter : ConnectInfo -> IO (Either OracleError ())
test_RebindParameter cfg =
  withConnection cfg $ \conn =>
    withStatement conn
      """
      INSERT INTO people(id,name)
      VALUES(people_seq.NEXTVAL,:name)
      """
      $ \stmt =>
          bind stmt [MkBindParameter ":name" (OracleString "Alice")]
          >>== \_ =>
          execute stmt
          >>== \_ =>
          bind stmt [MkBindParameter ":name" (OracleString "Bob")]
          >>== \_ =>
          execute stmt
