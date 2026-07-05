module QueryTests

import Oracle
import System
import Utils

%default total

||| Verify that a query returning no matching rows produces an empty result set.
|||
export covering
test_QueryNoRows : Connection -> IO (Either OracleError ())
test_QueryNoRows conn = do
  result <- do
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT id, name
        FROM people
        WHERE age = -1
        """
        []
  case result of
    Left err   =>
      die (show err)
    Right rows =>
      case rows of
        [] =>
          pure (Right ())
        _ =>
          die "Expected query to return no rows."

||| Verify that a query returning exactly one row is decoded correctly.
|||
export covering
test_QuerySingleRow : Connection -> IO (Either OracleError ())
test_QuerySingleRow conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT created_at
        FROM people
        WHERE name = 'Alice'
        """
        []
  case result of
    Left err   =>
      die (show err)
    Right rows => do
      putStrLn (show rows)
      case rows of
        [[OracleString "Alice"]] =>
          pure (Right ())
        _ =>
          die "Expected exactly one row containing Alice."

||| Verify that multiple rows are returned in the expected order.
|||
export covering
test_QueryMultipleRows : Connection -> IO (Either OracleError ())
test_QueryMultipleRows conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT name
        FROM people
        ORDER BY id
        """
        []
  case result of
    Left err =>
      die (show err)
    Right rows =>
      case rows of
        [ [OracleString "Alice"]
        , [OracleString "Bob"]
        ] =>
          pure (Right ())
        _ =>
          die "Expected two rows (Alice, Bob)."

||| Verify that query fetches every row from the result set.
|||
export covering
test_QueryAllRows : Connection -> IO (Either OracleError ())
test_QueryAllRows conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT id
        FROM people
        ORDER BY id
        """
        []
  case result of
    Left err =>
      die (show err)
    Right rows =>
      case length rows == 2 of
        True =>
          pure (Right ())
        False =>
          die "Expected query to return every row."

||| Verify that bind parameters participate correctly in query predicates.
|||
export covering
test_QueryWithWhereClause : Connection -> IO (Either OracleError ())
test_QueryWithWhereClause conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT age
        FROM people
        WHERE name = :name
        """
        [ MkBindParameter
            ":name"
            (OracleString "Bob")
        ]
  case result of
    Left err =>
      die (show err)
    Right rows =>
      case rows of
        [[OracleInt 42]] =>
          pure (Right ())
        _ =>
          die "Expected Bob's age to be returned."
