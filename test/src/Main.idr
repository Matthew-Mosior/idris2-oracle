module Main

import BindTests
import ConnectInfoTest
import ConnectionTests
import Oracle
import QueryTests
import StatementTests
import System
import TransactionTests
import TypedEncodingDecodingTests
import Utils

main : IO ()
main = do
  result <-
    withConnection connectinfo $ \conn =>
      setupTestUserAndinstallSchema conn >>== \_ =>
      resetDatabase conn >>== \_ =>
      test_OpenConnection connectinfo >>== \_ =>
      test_WithConnection connectinfo >>== \_ =>
      test_SequentialConnections connectinfo >>== \_ =>
      test_InvalidPassword connectinfo >>== \_ =>
      test_InvalidService connectinfo >>== \_ =>
      test_Prepare conn >>== \_ =>
      test_Release conn >>== \_ =>
      test_WithStatement conn >>== \_ =>
      test_Execute conn >>== \_ =>
      test_ReuseStatement conn >>== \_ =>
      test_SequentialStatements conn >>== \_ =>
      test_ConcurrentStatements conn >>== \_ =>
      test_BindNull conn >>== \_ =>
      test_BindString conn >>== \_ =>
      test_BindEmptyString conn >>== \_ =>
      test_BindInt conn >>== \_ =>
      test_BindDouble conn >>== \_ =>
      test_BindBoolTrue conn >>== \_ =>
      test_BindBoolFalse conn >>== \_ =>
      test_BindClob conn >>== \_ =>
      test_BindBlob conn >>== \_ =>
      test_BindTimestamp conn >>== \_ =>
      test_BindTimestampTZ conn >>== \_ =>
      test_BindIntervalYM conn >>== \_ =>
      test_BindIntervalDS conn >>== \_ =>
      test_BindManyParameters conn >>== \_ =>
      test_RebindParameter conn >>== \_ =>
      test_QueryNoRows conn >>== \_ =>
      test_QuerySingleRow conn >>== \_ =>
      test_QueryMultipleRows conn >>== \_ =>
      test_QueryAllRows conn >>== \_ =>
      test_QueryWithWhereClause conn >>== \_ =>
      test_QueryTypedPeople conn >>== \_ =>
      test_QueryOneTyped conn >>== \_ =>
      test_QueryOneMissing conn >>== \_ =>
      test_QueryExactlyOneTyped conn >>== \_ =>
      test_QueryExactlyOneMissing conn >>== \_ =>
      test_QueryExactlyOneMultiple conn >>== \_ =>
      test_QueryTypedBlobs conn >>== \_ =>
      test_CommitPersistsChanges conn >>== \_ =>
      test_RollbackDiscardsChanges conn >>== \_ =>
      test_CommitPersistsUpdate conn >>== \_ =>
      test_RollbackDiscardsUpdate conn >>== \_ =>
      test_CommitPersistsDelete conn >>== \_ =>
      test_RollbackRestoresDelete conn >>== \_ =>
      test_CommitMultipleStatements conn >>== \_ =>
      test_RollbackMultipleStatements conn
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
