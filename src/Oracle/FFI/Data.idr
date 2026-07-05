module Oracle.FFI.Data

||| Returns 1 if the dpiData is NULL.
|||
export %foreign "C:oracle_data_is_null,oracle-idris"
prim__dataIsNull : AnyPtr -> PrimIO Int32

||| Extract Int64 value.
|||
export %foreign "C:oracle_data_int64,oracle-idris"
prim__dataInt64 : AnyPtr -> PrimIO Int64

||| Extract Double value.
|||
export %foreign "C:oracle_data_double,oracle-idris"
prim__dataDouble : AnyPtr -> PrimIO Double

||| Extract String value.
|||
export %foreign "C:oracle_data_string,oracle-idris"
prim__dataString : AnyPtr -> PrimIO String
