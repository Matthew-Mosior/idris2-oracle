module Main

import ConnectInfoTest
import ConnectionTests
import Oracle
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
      test_InvalidService connectinfo
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
