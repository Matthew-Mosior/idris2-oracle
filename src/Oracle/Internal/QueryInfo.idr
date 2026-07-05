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
  result <- runElinIO (withQueryInfo' stmt column)
  case result of
    Right value =>
      case value of
        Left err     =>
          pure (Left err)
        Right value' =>
          pure (Right value')
    Left err    =>
      assert_total $ idris_crash "Data.Oracle.Internal.withQueryInfo: \{show err}"
  where
    acquire : AnyPtr -> Int32 -> F1 World AnyPtr
    acquire stmt column =
      ioToF1 (primIO (prim__queryInfo stmt column))
    use : AnyPtr -> F1 World (Either OracleError a)
    use ptr =
      ioToF1 ( do case prim__nullAnyPtr ptr == 1 of
                    True  => do
                      lasterr <- getLastError
                      pure (Left lasterr)
                    False => do
                      ptr' <- action ptr
                      pure (Right ptr')
             )
    release : AnyPtr -> F1' World
    release ptr =
      ioToF1 (primIO (prim__queryInfoFree ptr))
    withQueryInfo' : AnyPtr -> Int32 -> Elin World [] (Either OracleError a)
    withQueryInfo' stmt column =
      bracket (runIO (acquire stmt column))
              (\ptr => runIO (use ptr))
              (\ptr => runIO (release ptr))
