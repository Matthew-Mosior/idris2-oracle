module JSONTests

import Data.List
import Derive.Prelude
import JSON.Derive
import Oracle
import Oracle.Types.Value
import Oracle.Types.BindParameter
import System
import Utils

%language ElabReflection

||| The JSON representation stored in PEOPLE.profile.
|||
record PersonProfile where
  constructor MkPersonProfile
  department : String
  skills     : List String
  active     : Bool

%runElab derive "PersonProfile" [Show,Eq,ToJSON,FromJSON]

||| Test retrieving a single JSON value.
|||
||| The query selects Alice's JSON profile and verifies that the JSON value is serialized to its textual representation.
|||
export
test_QueryJSON : Connection -> IO (Either OracleError ())
test_QueryJSON conn = do
  result <- queryJSON conn ( MkJSONQuery "profile"
                                         "people WHERE name = :name"
                                         [MkBindParameter ":name" (OracleString "Alice")]
                           )
  case result of
    Left err   =>
      pure (Left err)
    Right json =>
      case json == "{\"department\":\"Engineering\",\"skills\":[\"Idris2\",\"Haskell\",\"C\"],\"active\":true}" of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Non-matching json response"
                            "JSONTests.test_QueryJSON"
                            False

||| Test retrieving multiple JSON values.
|||
||| The rows are ordered by ID so the result order is deterministic.
|||
export
test_QueryJSONList : Connection -> IO (Either OracleError ())
test_QueryJSONList conn = do
  result <- queryJSONList conn ( MkJSONQuery "profile"
                                             "people ORDER BY id"
                                             []
                               )
  case result of
    Left err    =>
      pure (Left err)
    Right jsons =>
      case length jsons == 2 of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Non-matching row length (expected 2 rows)"
                            "JSONTests.test_QueryJSONList"
                            False

||| Test that queryJSON returns the expected JSON values for both rows when queried individually.
|||
||| This additionally verifies that the JSON serialization is stable regardless of which row is selected.
|||
export
test_QueryJSONRows : Connection -> IO (Either OracleError ())
test_QueryJSONRows conn = do
  aliceresult <- queryJSON conn ( MkJSONQuery "profile"
                                              "people WHERE name = :name"
                                              [MkBindParameter ":name" (OracleString "Alice")]
                                )
  bobresult <- queryJSON conn ( MkJSONQuery "profile"
                                            "people WHERE name = :name"
                                            [MkBindParameter ":name" (OracleString "Bob")]
                              )
  case (aliceresult, bobresult) of
    (Right alice, Right bob) =>
      case alice == "{\"department\":\"Engineering\",\"skills\":[\"Idris2\",\"Haskell\",\"C\"],\"active\":true}" &&
           bob   == "{\"department\":\"Research\",\"skills\":[\"Python\",\"R\"],\"active\":false}" of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            ("Non-matching json response, " ++ "Alice: " ++ show alice ++ ", Bob: " ++ show bob)
                            "JSONTests.test_QueryJSONRows"
                            False
    (alice, bob) =>
      pure $
        Left $
          MkOracleError (-1)
                        "Non-matching json response"
                        "JSONTests.test_QueryJSONRows"
                        False

||| Test queryJSON with a bind parameter that matches no rows.
|||
||| queryJSON is expected to fail or otherwise report that there is no JSON result according to its documented single-row semantics.
|||
export
test_QueryJSONNoRows : Connection -> IO (Either OracleError ())
test_QueryJSONNoRows conn = do
  result <- queryJSON conn ( MkJSONQuery "profile"
                                         "people WHERE name = :name"
                                         [MkBindParameter ":name" (OracleString "DoesNotExist")]
                           )
  case result of
    Left _    =>
      pure (Right ())
    Right err =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "JSONTests.test_QueryJSONRows"
                        False

||| Test queryJSONList with a bind parameter.
|||
||| This verifies that JSONQuery.binds is correctly forwarded through the JSON query execution path.
|||
export
test_QueryJSONListWithBind : Connection -> IO (Either OracleError ())
test_QueryJSONListWithBind conn = do
  result <- queryJSONList conn ( MkJSONQuery "profile"
                                             "people WHERE name LIKE :prefix ORDER BY id"
                                             [MkBindParameter ":prefix" (OracleString "%")]
                               )
  case result of
    Left err    =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "JSONTests.test_QueryJSONListWithBind"
                        False
    Right jsons =>
      case length jsons == 2 of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Non-matching row length (expected 2 rows)"
                            "JSONTests.test_QueryJSONListWithBind"
                            False

||| Test decoding a JSON query result using queryJSONAs.
|||
||| This assumes a FromOracle instance exists for String and that queryJSONAs uses the same JSON_SERIALIZE(... RETURNING CLOB) query path as queryJSON.
|||
export
test_QueryJSONAs : Connection -> IO (Either OracleError ())
test_QueryJSONAs conn = do
  result <- queryJSONAs conn ( MkJSONQuery "profile"
                                           "people WHERE name = :name"
                                           [MkBindParameter ":name" (OracleString "Alice")]
                             )
  case result of
    Left err   =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "JSONTests.test_QueryJSONAs"
                        False
    Right json =>
      case json == MkPersonProfile "Engineering" ["Idris2", "Haskell", "C"] True of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            ("Non-matching decoded PersonProfile: " ++ show json)
                            "JSONTests.test_QueryJSONAs"
                            False

||| Test decoding a list of JSON query results using queryJSONListAs.
|||
||| This assumes a FromOracle instance exists for String and that queryJSONListAs uses the same JSON_SERIALIZE(... RETURNING CLOB) query path as queryJSON.
|||
export
test_QueryJSONListAs : Connection -> IO (Either OracleError ())
test_QueryJSONListAs conn = do
  let expected =
        [ MkPersonProfile "Engineering" ["Idris2", "Haskell", "C"] True
        , MkPersonProfile "Research" ["Python", "R"] False
        ]
  result <- queryJSONListAs conn ( MkJSONQuery "profile"
                                               "people ORDER BY id"
                                               []
                                 )
  case result of
    Left err       =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "JSONTests.test_QueryJSONListAs"
                        False
    Right profiles =>
      case profiles == expected of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            ("Non-matching decoded PersonProfile records: " ++ show profiles)
                            "JSONTests.test_QueryJSONListAs"
                            False

||| Test that queryJSONAs can decode multiple JSON values.
|||
||| The exact return type here depends on the generic API exposed by queryJSONAs.
||| If queryJSONAs is intended to decode a single value, this test should instead be implemented against queryJSONList.
|||
export
test_QueryJSONAsList : Connection -> IO (Either OracleError ())
test_QueryJSONAsList conn = do
  result <- queryJSONList conn ( MkJSONQuery "profile"
                                             "people ORDER BY id"
                                             []
                               )
  case result of
    Left err    =>
      pure $
        Left $
          MkOracleError (-1)
                        (show err)
                        "JSONTests.test_QueryJSONAsList"
                        False
    Right jsons =>
      case length jsons == 2 of
        True  =>
          pure (Right ())
        False =>
          pure $
            Left $
              MkOracleError (-1)
                            "Non-matching row length (expected 2 rows)"
                            "JSONTests.test_QueryJSONAsList"
                            False          
