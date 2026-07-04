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
      test_Prepare connectinfo >>== \_ =>
      test_Release connectinfo >>== \_ =>
      test_WithStatement connectinfo >>== \_ =>
      test_ReuseStatement connectinfo >>== \_ =>
      test_SequentialStatements connectinfo >>== \_ =>
      test_ConcurrentStatements connectinfo >>== \_ =>
      test_BindNull connectinfo >>== \_ =>
      test_BindString connectinfo >>== \_ =>
      test_BindInt connectinfo >>== \_ =>
      test_BindDouble connectinfo >>== \_ =>
      test_BindBoolTrue connectinfo >>== \_ =>
      test_BindBoolFalse connectinfo >>== \_ =>
      test_BindClob connectinfo >>== \_ =>
      test_BindBlob connectinfo >>== \_ =>
      test_BindDate connectinfo >>== \_ =>
      test_BindTimestamp connectinfo >>== \_ =>
      test_BindTimestampTZ connectinfo >>== \_ =>
      test_BindTimestampLTZ connectinfo >>== \_ =>
      test_BindIntervalYM connectinfo >>== \_ =>
      test_BindIntervalDS connectinfo >>== \_ =>
      test_BindManyParameters connectinfo >>== \_ =>
      test_RebindParameter connectinfo
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
