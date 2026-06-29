module Main

import ConnectionTests

main : IO ()
main = do
  test_OpenConnection connectinfo
  test_WithConnection connectinfo
  test_SequentialConnections connectinfo
  test_InvalidPassword connectinfo
  test_InvalidService connectinfo
