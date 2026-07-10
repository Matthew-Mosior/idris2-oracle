module TransactionTests

import Data.ByteString
import Derive.Prelude
import Oracle
import Oracle.Types.DateTime
import System
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
      die ("Unexpected rows: " ++ show rows)
    Left err                 =>
      die (show err)
