module Oracle.Internal.Decode

import Data.ByteString
import Oracle.Error
import Oracle.FFI.Data
import Oracle.FFI.DateTime
import Oracle.FFI.Lob
import Oracle.FFI.QueryInfo
import Oracle.FFI.Statement
import Oracle.Internal.QueryInfo
import Oracle.Types.DateTime
import Oracle.Types.OracleType
import Oracle.Types.Value
import Oracle.Types.Error
import PrimIO

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
  inforesult <- withQueryInfo stmt column pure
  case inforesult of
    Left err   =>
      pure (Left err)
    Right info => do
      tynum   <- primIO (prim__queryInfoType info)
      dataptr <- primIO (prim__columnValue stmt column)
      -- NULL pointer here means dpiStmt_getQueryValue() failed.
      case prim__nullAnyPtr dataptr == 1 of
        True  => do
          err <- getLastError
          pure (Left err)
        False => do
          isnull <- primIO (prim__dataIsNull dataptr)
          case  isnull /= 0 of
            True  =>
              pure (Right OracleNull)
            False => do
              nativety <- primIO (prim__queryValueNativeType dataptr)
              case fromOracleTypeNum tynum of
                OracleTypeVarchar   =>
                  Right . OracleString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeNumber    =>
                  case nativety of
                    3000 =>
                      Right . OracleInt <$>
                        primIO (prim__dataInt64 dataptr)
                    3001 =>
                      Right . OracleDouble <$>
                        primIO (prim__dataDouble dataptr)
                    _    =>
                      Right . OracleString <$>
                        primIO (prim__dataString dataptr)
                OracleTypeRaw       =>
                  Right . OracleBlob . fromString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeDate      => do
                  ts <- primIO (prim__dataTimestamp dataptr)
                  pure $
                    Right $
                      OracleDate $
                        MkOracleDate
                          !(primIO (prim__timestampYear ts))
                          !(primIO (prim__timestampMonth ts))
                          !(primIO (prim__timestampDay ts))
                          !(primIO (prim__timestampHour ts))
                          !(primIO (prim__timestampMinute ts))
                          !(primIO (prim__timestampSecond ts))
                OracleTypeTimestamp => do
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
                OracleTypeTimestampLTZ => do
                  ts <- primIO (prim__dataTimestamp dataptr)
                  pure $
                    Right $
                      OracleTimestampLTZ $
                        MkOracleTimestamp
                          !(primIO (prim__timestampYear ts))
                          !(primIO (prim__timestampMonth ts))
                          !(primIO (prim__timestampDay ts))
                          !(primIO (prim__timestampHour ts))
                          !(primIO (prim__timestampMinute ts))
                          !(primIO (prim__timestampSecond ts))
                          !(primIO (prim__timestampNanosecond ts))
                OracleTypeIntervalYM => do
                  iv <- primIO (prim__dataIntervalYM dataptr)
                  pure $
                    Right $
                      OracleIntervalYM $
                        MkOracleIntervalYM
                          !(primIO (prim__intervalYMYears iv))
                          !(primIO (prim__intervalYMMonths iv))
                OracleTypeIntervalDS => do
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
                OracleTypeBlob      => do
                  lob <- primIO (prim__dataLob dataptr)
                  case prim__nullAnyPtr lob == 1 of
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
                          primIO (prim__lobFreeBuffer bytes)
                          pure (Right $ OracleBlob $ fromString bytes)
                OracleTypeClob      => do
                  lob <- primIO (prim__dataLob dataptr)
                  case prim__nullAnyPtr lob == 1 of
                    True  => do
                      lasterr <- getLastError
                      pure (Left lasterr)
                    False => do
                      text <- primIO (prim__clobRead lob)
                      primIO (prim__lobFreeBuffer text)
                      pure (Right $ OracleClob text)
                OracleTypeUnknown n =>
                  pure $
                    Left $
                      MkOracleError
                        (-1)
                        ("Unsupported Oracle type: " ++ show n)
                        "decodeColumn"
                        False
