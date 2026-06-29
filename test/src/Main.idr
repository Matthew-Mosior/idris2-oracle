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
      resetDatabase conn >>== \_ => do
        test_OpenConnection conn
        test_WithConnection conn
        test_SequentialConnections conn
        test_InvalidPassword conn
        test_InvalidService conn
  case result of
    Left err =>
      die (show err)
    Right _  =>
      pure ()
