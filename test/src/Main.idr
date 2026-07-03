module Main

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
      test_ConcurrentStatements connectinfo
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
