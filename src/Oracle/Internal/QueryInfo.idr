module Oracle.Internal.QueryInfo

import Control.Monad.Elin
import Control.Monad.MCancel
import Data.Linear.Ref1
import Oracle.Error
import Oracle.FFI.QueryInfo
import Oracle.Types.ColumnInfo
import Oracle.Types.Error
import Oracle.Types.OracleType

||| Convert a dpiQueryInfo structure into a ColumnInfo record.
|||
export
queryColumnInfo : AnyPtr -> IO (Either OracleError ColumnInfo)
queryColumnInfo info = do
  name     <- primIO (prim__queryInfoName info)
  ty       <- primIO (prim__queryInfoType info)
  size     <- primIO (prim__queryInfoSize info)
  nullable <- primIO (prim__queryInfoNullable info)
  pure $
    Right $
      MkColumnInfo
        name
        (fromOracleTypeNum ty)
        (cast size)
        (nullable /= 0)

||| Acquire a dpiQueryInfo structure, execute an action, and guarantee cleanup.
|||
export
withQueryInfo : AnyPtr -> Int32 -> (AnyPtr -> IO a) -> IO (Either OracleError a)
withQueryInfo stmt column action = do
  ptr <- primIO (prim__queryInfo stmt column)
  case prim__nullAnyPtr ptr == 1 of
    True  =>
      Left <$> getLastError
    False => do
      res <- runElinIO (withQueryInfo' ptr)
      case res of
        Right res' =>
          pure (Right res')
        Left err   =>
          assert_total $ idris_crash "Data.Oracle.Internal.QueryInfo: \{show err}"
  where
    acquire : AnyPtr -> Elin World [] AnyPtr
    acquire ptr =
      liftIO $ pure ptr
    release : AnyPtr -> Elin World [] ()
    release ptr =
     liftIO $ primIO (prim__queryInfoFree ptr)
    use : AnyPtr -> Elin World [] a
    use ptr =
      liftIO $ action ptr
    withQueryInfo' : AnyPtr -> Elin World [] a
    withQueryInfo' ptr =
      bracket (acquire ptr)
              use
              release
