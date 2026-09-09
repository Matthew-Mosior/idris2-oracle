module Oracle.FFI.Data

||| Returns 1 if the dpiData is NULL.
|||
export %foreign "C:oracle_data_is_null,oracle-idris"
prim__dataIsNull : AnyPtr -> PrimIO Int32

||| Extract Double value.
|||
export %foreign "C:oracle_data_double,oracle-idris"
prim__dataDouble : AnyPtr -> PrimIO Double

||| Extract a BINARY_FLOAT value.
|||
||| The C layer widens the native 32-bit floating-point value to a C double
||| before returning it across the Idris FFI.
|||
export %foreign "C:oracle_data_binary_float,oracle-idris"
prim__dataBinaryFloat : AnyPtr -> PrimIO Double

||| Extract a BINARY_DOUBLE value.
|||
||| The value is returned directly as a C double.
|||
export %foreign "C:oracle_data_binary_double,oracle-idris"
prim__dataBinaryDouble : AnyPtr -> PrimIO Double

||| Extract String value.
|||
export %foreign "C:oracle_data_string,oracle-idris"
prim__dataString : AnyPtr -> PrimIO String

||| Extract Boolean value.
|||
export %foreign "C:oracle_data_bool,oracle-idris"
prim__dataBool : AnyPtr -> PrimIO Int32
