module Oracle.Internal.Lob

import Data.ByteString
import Oracle.Error
import Oracle.FFI.Lob
import Oracle.Types.Error

||| Read an Oracle BLOB into a ByteString.
|||
||| The LOB handle is released after reading.
|||
export
readBlob : AnyPtr -> IO (Either OracleError ByteString)
readBlob lob = do
  size <- primIO (prim__lobSize lob)
  case size < 0 of
    True  => do
      lasterr <- getLastError
      pure (Left lasterr)
    False => do
      blobdata <- primIO (prim__lobRead lob 1 size)
      primIO (prim__lobRelease lob)
      pure (Right $ fromString blobdata)
