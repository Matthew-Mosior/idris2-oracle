module StatementTests

import Oracle
import System

%default total

||| Verify that a SQL statement may be prepared successfully.
|||
||| This exercises statement preparation independently of execution.
|||
export
test_Prepare : Connection -> IO (Either OracleError ())
test_Prepare conn = do
  result <-
    prepare
    conn
    "SELECT 1 FROM dual"
  case result of
    Left err   =>
      pure (Left err)
    Right stmt => do
      release stmt
      pure (Right ())

||| Verify that a prepared statement may be released explicitly.
|||
||| This exercises the statement release API directly.
|||
export
test_Release : Connection -> IO (Either OracleError ())
test_Release conn = do
  result <-
    prepare
    conn
    "SELECT 1 FROM dual"
  case result of
    Left err   =>
      pure (Left err)
    Right stmt => do
      release stmt
      pure (Right ())

||| Verify that `withStatement` automatically releases the prepared statement.
|||
||| A trivial query is executed to prove that the prepared statement is usable.
|||
export
test_WithStatement : Connection -> IO (Either OracleError ())
test_WithStatement conn = do
  result <-
    withStatement
      conn
      "SELECT 1 FROM dual"
      (\stmt =>
         execute stmt
      )
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify that a prepared statement may be executed successfully.
|||
||| Executes a trivial query against DUAL.
|||
export
test_Execute : Connection -> IO (Either OracleError ())
test_Execute conn = do
  result <-
    prepare
    conn
    "SELECT 1 FROM dual"
  case result of
    Left err =>
      pure (Left err)
    Right stmt => do
      executed <- execute stmt
      release stmt
      pure executed

||| Verify that a prepared statement may be executed multiple times.
|||
||| The same prepared statement is reused repeatedly without being re-prepared.
|||
export
test_ReuseStatement : Connection -> IO (Either OracleError ())
test_ReuseStatement conn = do
  result <-
    prepare
    conn
    "SELECT 1 FROM dual"
  case result of
    Left err =>
      pure (Left err)
    Right stmt => do
      let
        loop : Nat -> IO (Either OracleError ())
        loop Z =
          pure (Right ())
        loop (S k) = do
          res <- execute stmt
          case res of
            Left err =>
              pure (Left err)
            Right () =>
              loop k
      executed <- loop 10
      release stmt
      pure executed

||| Verify that statements may be prepared and released repeatedly.
|||
||| This exercises repeated allocation and destruction of native Oracle statement handles.
|||
export
test_SequentialStatements : Connection -> IO (Either OracleError ())
test_SequentialStatements conn = do
  result <-
    let
      loop : Nat -> IO (Either OracleError ())
      loop Z =
        pure (Right ())
      loop (S k) = do
        prepared <-
          prepare
          conn
          "SELECT 1 FROM dual"
        case prepared of
          Left err =>
            pure (Left err)
          Right stmt => do
            release stmt
            loop k
      in loop 100
  case result of
    Left err =>
      die (show err)
    Right () =>
      pure (Right ())

||| Verify that multiple prepared statements may exist simultaneously.
|||
||| Every statement is executed before being released, ensuring multiple Oracle statement handles remain valid concurrently.
|||
export
test_ConcurrentStatements : Connection -> IO (Either OracleError ())
test_ConcurrentStatements conn = do
  result <-
    prepare conn "SELECT 1 FROM dual"
  case result of
    Left err => pure (Left err)
    Right st1 => do
      s2 <- prepare conn "SELECT 1 FROM dual"
      case s2 of
        Left err => do
          release st1
          pure (Left err)
        Right st2 => do
          s3 <- prepare conn "SELECT 1 FROM dual"
          case s3 of
            Left err => do
              release st1
              release st2
              pure (Left err)
            Right st3 => do
              s4 <- prepare conn "SELECT 1 FROM dual"
              case s4 of
                Left err => do
                  release st1
                  release st2
                  release st3
                  pure (Left err)
                Right st4 => do
                  s5 <- prepare conn "SELECT 1 FROM dual"
                  case s5 of
                    Left err => do
                      release st1
                      release st2
                      release st3
                      release st4
                      pure (Left err)
                    Right st5 => do
                      r1 <- execute st1
                      r2 <- execute st2
                      r3 <- execute st3
                      r4 <- execute st4
                      r5 <- execute st5
                      release st1
                      release st2
                      release st3
                      release st4
                      release st5
                      case r1 of
                        Left err => pure (Left err)
                        Right () =>
                          case r2 of
                            Left err => pure (Left err)
                            Right () =>
                              case r3 of
                                Left err => pure (Left err)
                                Right () =>
                                  case r4 of
                                    Left err => pure (Left err)
                                    Right () =>
                                      case r5 of
                                        Left err => pure (Left err)
                                        Right () =>
                                          pure (Right ())
