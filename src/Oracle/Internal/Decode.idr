module Oracle.Internal.Decode

import Data.ByteString
import Oracle.Error
import Oracle.FFI.Data
import Oracle.FFI.Lob
import Oracle.FFI.QueryInfo
import Oracle.FFI.Statement
import Oracle.Internal.QueryInfo
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
  inforesult <-
    withQueryInfo stmt column pure
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
            False =>
              case fromOracleTypeNum tynum of
                OracleTypeVarchar   =>
                  Right . OracleString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeNumber    =>
                  Right . OracleInt <$>
                    primIO (prim__dataInt64 dataptr)
                OracleTypeRaw       =>
                  Right . OracleBlob . fromString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeDate      =>
                  Right . OracleString <$>
                    primIO (prim__dataString dataptr)
                OracleTypeTimestamp =>
                  Right . OracleString <$>
                    primIO (prim__dataString dataptr)
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
