module QueryTests

import Data.ByteString
import Oracle
import PersonAndBlob
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
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QueryNoRows"
                        False
    Right rows =>
      case rows of
        [] =>
          pure (Right ())
        _  =>
          pure $
            Left $
              MkOracleError (-1)
                            "Expected query to return no rows"
                            "QueryTests.test_QueryNoRows"
                            False

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
        SELECT name
        FROM people
        WHERE name = 'Alice'
        """
        []
  case result of
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QuerySingleRow"
                        False
    Right rows =>
      case rows of
        [[OracleString "Alice"]] =>
          pure (Right ())
        _                        =>
          pure $
            Left $
              MkOracleError (-1)
                            "Expected exactly one row containing Alice"
                            "QueryTests.test_QuerySingleRow"
                            False

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
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QueryMultipleRows"
                        False
    Right rows =>
      case rows of
        [ [OracleString "Alice"]
        , [OracleString "Bob"]
        ] =>
          pure (Right ())
        _ =>
          pure $
            Left $
              MkOracleError (-1)
                            "Expected two rows (Alice, Bob)"
                            "QueryTests.test_QueryMultipleRows"
                            False

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
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QueryAllRows"
                        False
    Right rows =>
      case length rows == 2 of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Expected query to return every row"
                            "QueryTests.test_QueryAllRows"
                            False

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
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QueryWithWhereClause"
                        False
    Right rows =>
      case rows of
        [[OracleNumber 42.0]] =>
          pure (Right ())
        rows'            =>
          pure $
            Left $
              MkOracleError (-1)
                            "Expected Bob's age to be returned"
                            "QueryTests.test_QueryWithWhereClause"
                            False

||| Verify that queryAs decodes every returned row using the existing PersonRow FromRow implementation.
|||
export covering
test_QueryAs : Connection -> IO (Either OracleError ())
test_QueryAs conn = do
  resetDatabase conn >>== \_ => do
    people : Either OracleError (List PersonRow) <-
      queryAs
        conn
        ( MkQuery
            [ Column "name"
            , Column "age"
            , Column "salary"
            , Column "active"
            , Column "notes"
            , Column "legacy_date"
            , Column "hire_timestamp"
            , Column "meeting_time_tz"
            , Column "vacation_length"
            , Column "uptime"
            ]
            "people ORDER BY id"
            []
        )
    case people of
      Right [ alice, bob ] =>
        case (alice.name, alice.age, bob.name, bob.age) of
          ("Alice", 30.0, "Bob", 42.0) =>
            pure (Right ())
          _                            =>
            pure $
              Left $
                MkOracleError
                  (-1)
                  "Expected Alice and Bob to be decoded correctly"
                  "QueryTests.test_QueryAs"
                  False
      _                    =>
        pure $
          Left $
            MkOracleError
              (-1)
              "Expected exactly two PersonRow values"
              "QueryTests.test_QueryAs"
              False

||| Verify that queryOneAs decodes a single row using the existing PersonRow FromRow implementation.
|||
export covering
test_QueryOneAs : Connection -> IO (Either OracleError ())
test_QueryOneAs conn = do
  resetDatabase conn >>== \_ => do
    person : Either OracleError PersonRow <-
      queryOneAs
        conn
        ( MkQuery
            [ Column "name"
            , Column "age"
            , Column "salary"
            , Column "active"
            , Column "notes"
            , Column "legacy_date"
            , Column "hire_timestamp"
            , Column "meeting_time_tz"
            , Column "vacation_length"
            , Column "uptime"
            ]
            "people WHERE name = 'Alice'"
            []
        )
    case person of
      Right person' =>
        case (person'.name, person'.age) of
          ("Alice", 30.0) =>
            pure (Right ())
          _               =>
            pure $
              Left $
                MkOracleError
                  (-1)
                  "Wrong data for Alice"
                  "QueryTests.test_QueryOneAs"
                  False
      _             =>
        pure $
          Left $
            MkOracleError
              (-1)
              "Expected PersonRow for Alice"
              "QueryTests.test_QueryOneAs"
              False

||| Verify that CHAR, NCHAR, and NVARCHAR2 values are decoded as OracleString.
|||
export covering
test_QueryCharacterTypes : Connection -> IO (Either OracleError ())
test_QueryCharacterTypes conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT varchar_value,char_value,nvarchar_value,nchar_value
        FROM character_types
        """
        []
  case result of
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "QueryTests.test_QueryCharacterTypes"
                        False
    Right rows =>
      case rows of
        [ [ OracleString "hello"
          , OracleString "hello     "
          , OracleString "こんにちは"
          , OracleString "世界"
          ]
        ] =>
          pure (Right ())
        _ =>
          pure $
            Left $
              MkOracleError (-1)
                            ("Unexpected character type rows: " ++ show rows)
                            "QueryTests.test_QueryCharacterTypes"
                            False

||| Verify that RAW values are decoded as OracleRaw.
|||
export covering
test_QueryRawType : Connection -> IO (Either OracleError ())
test_QueryRawType conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT raw_value
        FROM raw_types
        """
        []
  case result of
    Left err   =>
      pure $
        Left $
          MkOracleError
            (-1)
            (show err)
            "QueryTests.test_QueryRawType"
            False
    Right rows =>
      case rows of
        [[OracleRaw bytes]] =>
          case bytes == expectedrawbytes of
            True =>
              pure (Right ())
            False =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    ("Unexpected RAW value: " ++ show bytes)
                    "QueryTests.test_QueryRawType"
                    False
        _                   =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Unexpected RAW rows: " ++ show rows)
                "QueryTests.test_QueryRawType"
                False
  where
    ||| Expected binary value stored in raw_types.raw_value.
    |||
    expectedrawbytes : ByteString
    expectedrawbytes =
      pack [0x00, 0xFF, 0x01, 0x80, 0x41, 0x42]

||| Verify that BINARY_FLOAT and BINARY_DOUBLE values are decoded correctly.
|||
export covering
test_QueryBinaryFloatingTypes : Connection -> IO (Either OracleError ())
test_QueryBinaryFloatingTypes conn = do
  result <-
    resetDatabase conn >>==
    \_ =>
      query conn
        """
        SELECT binary_float_value,binary_double_value
        FROM floating_types
        """
        []
  case result of
    Left err =>
      pure $
        Left $
          MkOracleError
            (-1)
            (show err)
            "QueryTests.test_QueryBinaryFloatingTypes"
            False
    Right rows =>
      case rows of
        [[OracleBinaryFloat 1.5, OracleBinaryDouble binarydouble]] =>
          case binarydouble == expectedbinarydouble of
            True  =>
              pure (Right())
            False =>
              pure $
                Left $
                  MkOracleError
                    (-1)
                    ("Unexpected BINARY_DOUBLE value: " ++ show binarydouble)
                    "QueryTests.test_QueryBinaryFloatingTypes"
                    False
        _ =>
          pure $
            Left $
              MkOracleError
                (-1)
                ("Unexpected floating type rows: " ++ show rows)
                "QueryTests.test_QueryBinaryFloatingTypes"
                False
  where
    ||| Expected binary double value stored in floating_types.binary_double_value.
    expectedbinarydouble : Double
    expectedbinarydouble = -42.25
