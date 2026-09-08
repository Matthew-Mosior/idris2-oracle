module Oracle.FFI.Raw

%default total

||| Read bytes from a dpiData pointer.
|||
||| Parameters:
||| - dpiData pointer
|||
||| Returns:
||| - Allocated buffer containing the data.
|||
||| The returned buffer must be released with `oracle_lob_free_buffer`.
|||
export %foreign "C:oracle_data_bytes_hex,oracle-idris"
prim__dataBytesHex : AnyPtr -> PrimIO String
