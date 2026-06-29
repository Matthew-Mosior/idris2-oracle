module Main

import ConnectionTests
import System

main : IO ()
main = do
  Right result <-
    withConnection connectinfo $ \conn =>
      installSchema conn >>== \_ =>
      resetDatabase conn >>== \_ => do
        test_OpenConnection conn
        test_WithConnection conn
        test_SequentialConnections conn
        test_InvalidPassword conn
        test_InvalidService conn
    | Left err =>
        die (show err)
