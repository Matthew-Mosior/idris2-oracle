module Oracle.FFI.Lob

%default total

||| Retrieve the LOB handle stored inside a dpiData value.
|||
||| Parameters:
||| - dpiData pointer
|||
||| Returns:
||| - dpiLob pointer.
||| - NULL if no LOB is present.
|||
||| The returned LOB handle is owned by the statement row and must not be released with `oracle_lob_release`.
|||
export %foreign "C:oracle_data_lob"
prim__dataLob : AnyPtr -> PrimIO AnyPtr

||| Retrieve the byte size of a LOB.
|||
||| Returns:
||| - Size of the LOB.
||| - Negative value on failure.
|||
export %foreign "C:oracle_lob_size"
prim__lobSize : AnyPtr -> PrimIO Int64

||| Read bytes from a BLOB.
|||
||| Parameters:
||| - LOB handle
||| - offset
||| - length
|||
||| Returns:
||| - Allocated buffer containing the data.
|||
||| The returned buffer must be released with `oracle_lob_free_buffer`.
|||
export %foreign "C:oracle_lob_read"
prim__lobRead : AnyPtr -> Int64 -> Int64 -> PrimIO String

||| Read a CLOB as UTF-8 text.
|||
||| The returned string is allocated by the C layer and must be released.
|||
export %foreign "C:oracle_clob_read"
prim__clobRead : AnyPtr -> PrimIO String

||| Release a LOB handle.
|||
export %foreign "C:oracle_lob_release"
prim__lobRelease : AnyPtr -> PrimIO ()

||| Release memory returned by LOB reads.
|||
export %foreign "C:oracle_lob_free_buffer"
prim__lobFreeBuffer : String -> PrimIO ()
