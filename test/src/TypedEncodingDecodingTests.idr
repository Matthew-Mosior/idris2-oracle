module TypedEncodingDecodingTests

import Data.ByteString
import Oracle
import Oracle.Types.DateTime
import PersonRow
import Utils

export covering
test_QueryTypedPeople : Connection -> IO (Either OracleError ())
test_QueryTypedPeople conn = do
  result : Either OracleError (List PersonRow) <-
    resetDatabase conn >>==
    \_ =>
      query_
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
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
                        "TypedEncodingDecodingTests.test_QueryTypedPeople"
                        False
    Right rows =>
      case rows of
        [ MkPersonRow "Alice"
                      30
                      90000
                      True
                      "Alice Notes"
                      (MkOracleTimestamp 2022 5 10 9 15 30 123457000)
                      (MkOracleTimestampTZ 2025 7 1 10 45 30 987654000 (-5) 0)
                      (MkOracleIntervalYM 2 6)
                      (MkOracleIntervalDS 12 8 15 42 555000000)
        , MkPersonRow "Bob"
                      42
                      120000
                      False
                      "Bob Notes"
                      (MkOracleTimestamp 2015 1 8 16 45 1 0)
                      (MkOracleTimestampTZ 2025 1 1 0 0 0 0 (-5) 0)
                      (MkOracleIntervalYM 15 3)
                      (MkOracleIntervalDS 365 23 59 59 999999999)
        ]     =>
          pure (Right ())
        rows' =>
          pure $
            Left $
              MkOracleError (-1)
                            ("Unexpected decoded people: " ++ show rows')
                            "TypedEncodingDecodingTests.test_QueryTypedPeople"
                            False

export covering
test_QueryOneTyped : Connection -> IO (Either OracleError ())
test_QueryOneTyped conn = do
  result : Either OracleError (Maybe PersonRow) <-
    resetDatabase conn >>==
    \_ =>
      queryOne
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        WHERE name = :name
        """
        [MkBindParameter ":name" (OracleString "Bob")]
  case result of
    Left err                                          =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TypedEncodingDecodingTests.test_QueryOneTyped"
                        False
    Right (Just (MkPersonRow "Bob" 42 _ _ _ _ _ _ _)) =>
      pure (Right ())
    Right value                                       =>
      pure $
        Left $
          MkOracleError (-1)
                        "Expected Bob"
                        "TypedEncodingDecodingTests.test_QueryOneTyped"
                        False

export covering
test_QueryOneMissing : Connection -> IO (Either OracleError ())
test_QueryOneMissing conn = do
  result : Either OracleError (Maybe PersonRow) <-
    resetDatabase conn >>==
    \_ =>
      queryOne
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        WHERE name = :name
        """
        [MkBindParameter ":name" (OracleString "Nobody")]
  case result of
    Right Nothing =>
      pure (Right ())
    Right _       =>
      pure $
        Left $
          MkOracleError (-1)
                        "Expected Nothing"
                        "TypedEncodingDecodingTests.test_QueryOneMissing"
                        False
    Left err      =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TypedEncodingDecodingTests.test_QueryOneMissing"
                        False

export covering
test_QueryExactlyOneTyped : Connection -> IO (Either OracleError ())
test_QueryExactlyOneTyped conn = do
  result : Either OracleError PersonRow <-
    resetDatabase conn >>==
    \_ =>
      queryExactlyOne
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        WHERE name = :name
        """
        [MkBindParameter ":name" (OracleString "Alice")]
  case result of
    Right (MkPersonRow "Alice" 30 _ _ _ _ _ _ _) =>
      pure (Right ())
    Right row                                    =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Unexpected row: " ++ show row)
                        "TypedEncodingDecodingTests.test_QueryExactlyOneTyped"
                        False
    Left err =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TypedEncodingDecodingTests.test_QueryExactlyOneTyped"
                        False

export covering
test_QueryExactlyOneMissing : Connection -> IO (Either OracleError ())
test_QueryExactlyOneMissing conn = do
  result : Either OracleError PersonRow <-
    resetDatabase conn >>==
    \_ =>
      queryExactlyOne
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        WHERE name = :name
        """
        [MkBindParameter ":name" (OracleString "Nobody")]
  case result of
    Left _  =>
      pure (Right ())
    Right _ =>
      pure $
        Left $
          MkOracleError (-1)
                        "Expected failure"
                        "TypedEncodingDecodingTests.test_QueryExactlyOneMissing"
                        False

export covering
test_QueryExactlyOneMultiple : Connection -> IO (Either OracleError ())
test_QueryExactlyOneMultiple conn = do
  result : Either OracleError PersonRow <-
    resetDatabase conn >>==
    \_ =>
      queryExactlyOne
        conn
        """
        SELECT
            name,
            age,
            salary,
            active,
            notes,
            hire_timestamp,
            meeting_time_tz,
            vacation_length,
            uptime
        FROM people
        """
        []
  case result of
    Left _     =>
      pure (Right ())
    Right rows =>
      pure $
        Left $
          MkOracleError (-1)
                        ("Expected mutiple-row failure: " ++ show rows)
                        "TypedEncodingDecodingTests.test_QueryExactlyOneMultiple"
                        False

export covering
test_QueryTypedBlobs : Connection -> IO (Either OracleError ())
test_QueryTypedBlobs conn = do
  result : Either OracleError (List BlobsRow) <-
    resetDatabase conn >>==
    \_ =>
      query_
        conn
        """
        SELECT payload
        FROM blobs
        ORDER BY id
        """
        []
  case result of
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "TypedEncodingDecodingTests.test_QueryTypedBlobs"
                        False
    Right rows =>
      case rows == [ MkBlobsRow (pack [0x46, 0x46])
                   , MkBlobsRow (fromString "FF")
                   ] of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Unexpected blobs"
                            "TypedEncodingDecodingTests.test_QueryTypedBlobs"
                            False
