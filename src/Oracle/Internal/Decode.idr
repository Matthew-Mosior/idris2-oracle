module Oracle.Internal.Decode

import Control.Monad.Elin
import Control.Monad.MCancel
import Data.ByteString
import Data.Linear.Ref1
import Oracle.Error
import Oracle.FFI.Data
import Oracle.FFI.DateTime
import Oracle.FFI.Lob
import Oracle.FFI.QueryInfo
import Oracle.FFI.Statement
import Oracle.Internal.QueryInfo
import Oracle.Types.ColumnInfo
import Oracle.Types.DateTime
import Oracle.Types.OracleType
import Oracle.Types.Value
import Oracle.Types.Error

||| Retrieve metadata describing a query column.
|||
||| The underlying `dpiQueryInfo` structure is allocated only for the duration of this function.
|||
||| It is always released before returning, regardless of whether the supplied action succeeds.
|||
||| This is the preferred metadata API for query result decoding.
|||
export
getColumnInfo : AnyPtr -> Int32 -> IO (Either OracleError ColumnInfo)
getColumnInfo stmt column =
  withQueryInfo stmt column $ \info => do
    name     <- primIO (prim__queryInfoName info)
    tynum    <- primIO (prim__queryInfoType info)
    size     <- primIO (prim__queryInfoSize info)
    nullable <- primIO (prim__queryInfoNullable info)
    pure $
      MkColumnInfo
        name
        (fromOracleTypeNum tynum)
        (cast size)
        (nullable /= 0)

||| Decode the value of a single column in the current row.
|||
||| This function:
||| - Retrieves column metadata.
||| - Retrieves the current row value.
||| - Converts the Oracle value into an OracleValue.
|||
||| If Oracle fails to retrieve the value, the Oracle error is propagated instead of being interpreted as OracleNull.
|||
export
decodeColumn : AnyPtr -> Int32 -> IO (Either OracleError OracleValue)
decodeColumn stmt column = do
  inforesult <- getColumnInfo stmt column
  case inforesult of
    Left err   =>
      pure (Left err)
    Right info => do
      dataptr <- primIO (prim__columnValue stmt column)
      case prim__nullAnyPtr dataptr == 1 of
        True => do
          lasterr <- getLastError
          pure (Left lasterr)
        False => do
          isnull  <- primIO (prim__dataIsNull dataptr)
          case isnull /= 0 of
            True  =>
              pure (Right OracleNull)
            False => do
              case info.oracletype of
                OracleTypeVarchar     =>
                  Right . OracleString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeNumber      =>
                  Right . OracleNumber <$>
                    primIO (prim__dataDouble dataptr)
                OracleTypeRaw         =>
                  Right . OracleBlob . fromString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeTimestamp   => do
                  ts <- primIO (prim__dataTimestamp dataptr)
                  pure $
                    Right $
                       OracleTimestamp $
                         MkOracleTimestamp
                           !(primIO (prim__timestampYear ts))
                           !(primIO (prim__timestampMonth ts))
                           !(primIO (prim__timestampDay ts))
                           !(primIO (prim__timestampHour ts))
                           !(primIO (prim__timestampMinute ts))
                           !(primIO (prim__timestampSecond ts))
                           !(primIO (prim__timestampNanosecond ts))
                OracleTypeTimestampTZ => do
                  ts <- primIO (prim__dataTimestamp dataptr)
                  pure $
                    Right $
                      OracleTimestampTZ $
                        MkOracleTimestampTZ
                          !(primIO (prim__timestampYear ts))
                          !(primIO (prim__timestampMonth ts))
                          !(primIO (prim__timestampDay ts))
                          !(primIO (prim__timestampHour ts))
                          !(primIO (prim__timestampMinute ts))
                          !(primIO (prim__timestampSecond ts))
                          !(primIO (prim__timestampNanosecond ts))
                          !(primIO (prim__timestampTZHour ts))
                          !(primIO (prim__timestampTZMinute ts))
                OracleTypeIntervalYM  => do
                  iv <- primIO (prim__dataIntervalYM dataptr)
                  pure $
                    Right $
                      OracleIntervalYM $
                        MkOracleIntervalYM
                          !(primIO (prim__intervalYMYears iv))
                          !(primIO (prim__intervalYMMonths iv))
                OracleTypeIntervalDS  => do
                  iv <- primIO (prim__dataIntervalDS dataptr)
                  pure $
                    Right $
                      OracleIntervalDS $
                        MkOracleIntervalDS
                          !(primIO (prim__intervalDSDays iv))
                          !(primIO (prim__intervalDSHours iv))
                          !(primIO (prim__intervalDSMinutes iv))
                          !(primIO (prim__intervalDSSeconds iv))
                          !(primIO (prim__intervalDSNanoseconds iv))
                OracleTypeBlob        => do
                  result <- runElinIO (withLob dataptr OracleTypeBlob) 
                  case result of
                    Right value =>
                      case value of
                        Left err     =>
                          pure (Left err)
                        Right value' =>
                          pure (Right value')
                    Left err    =>
                      assert_total $ idris_crash "Oracle.Internal.Decode.decodeColumn: \{show err}"
                OracleTypeClob        => do
                  result <- runElinIO (withLob dataptr OracleTypeClob) 
                  case result of
                    Right value =>
                      case value of
                        Left err     =>
                          pure (Left err)
                        Right value' =>
                          pure (Right value')
                    Left err    =>
                      assert_total $ idris_crash "Oracle.Internal.Decode.decodeColumn: \{show err}"
                OracleTypeBoolean     => do
                  b <- primIO (prim__dataBool dataptr)
                  case b of
                    0 =>
                      pure (Right $ OracleBool False)
                    1 =>
                      pure (Right $ OracleBool True)
                    n =>
                      pure $
                        Left $
                          MkOracleError
                            (-1)
                            "Unsupported BOOLEAN: \{show n}"
                            "Oracle.Internal.Decode.decodeColumn"
                            False
                OracleTypeUnknown n   =>
                  pure $
                    Left $
                      MkOracleError
                        (-1)
                        ("Unsupported Oracle type: " ++ show n)
                        "Oracle.Internal.Decode.decodeColumn"
                        False
  where
    acquire : AnyPtr -> F1 World AnyPtr
    acquire dataptr =
      ioToF1 (primIO (prim__dataLob dataptr))
    use : AnyPtr -> OracleType -> F1 World (Either OracleError OracleValue)
    use lob oracletype =
      case oracletype of
        OracleTypeBlob =>
          ioToF1 ( do case prim__nullAnyPtr lob == 1 of
                        True  => do
                          lasterr <- getLastError
                          pure (Left lasterr)
                        False => do
                          size <- primIO (prim__lobSize lob)
                          case size < 0 of
                            True  => do
                              lasterr <- getLastError
                              pure (Left lasterr)
                            False => do
                              bytes <- primIO (prim__lobRead lob 1 size)
                              pure (Right $ OracleBlob $ fromString bytes)
                 )
        OracleTypeClob =>
          ioToF1 ( do case prim__nullAnyPtr lob == 1 of
                        True  => do
                          lasterr <- getLastError
                          pure (Left lasterr)
                        False => do
                          text <- primIO (prim__clobRead lob)
                          pure (Right $ OracleClob text)
                 )
        ty             =>
          ioToF1 ( pure $
                     Left $
                       MkOracleError
                         (-1)
                         "Unsupported type: \{show ty}"
                         "Oracle.Internal.Decode.decodeColumn.use"
                         False
                 )
    release : AnyPtr -> F1' World
    release lob =
      ioToF1 (primIO (prim__lobRelease lob))
    withLob : AnyPtr -> OracleType -> Elin World [] (Either OracleError OracleValue)
    withLob dataptr oracletype =
      bracket (runIO (acquire dataptr))
              (\lob => runIO (use lob oracletype))
              (\lob => runIO (release lob))
