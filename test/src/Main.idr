module Main

import BindTests
import ConnectInfoTest
import ConnectionTests
import Oracle
import StatementTests
import System
import Utils

main : IO ()
main = do
  result <-
    withConnection connectinfo $ \conn =>
      installSchema conn >>== \_ =>
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
      test_BindDate conn >>== \_ =>
      test_BindTimestamp conn >>== \_ =>
      test_BindTimestampTZ conn >>== \_ =>
      test_BindTimestampLTZ conn >>== \_ =>
      test_BindIntervalYM conn >>== \_ =>
      test_BindIntervalDS conn >>== \_ =>
      test_BindManyParameters conn >>== \_ =>
      test_RebindParameter conn
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
