module Oracle.FFI.Transaction

%default total

||| Commit the current transaction.
|||
||| Parameters:
||| - Oracle connection handle.
|||
||| Returns:
||| - 0 on success.
||| - Non-zero on failure.
|||
export %foreign "C:oracle_commit"
prim__commit : AnyPtr -> PrimIO Int32

||| Roll back the current transaction.
|||
||| Parameters:
||| - Oracle connection handle.
|||
||| Returns:
||| - 0 on success.
||| - Non-zero on failure.
|||
export %foreign "C:oracle_rollback"
prim__rollback : AnyPtr -> PrimIO Int32
