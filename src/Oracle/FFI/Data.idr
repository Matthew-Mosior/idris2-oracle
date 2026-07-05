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

||| Free a query value.
|||
export %foreign "C:oracle_query_value_free,oracle-idris"
prim__queryValueFree : AnyPtr -> PrimIO ()

||| Get the data of a query value.
|||
export %foreign "C:oracle_query_value_data,oracle-idris"
prim__queryValueData : AnyPtr -> PrimIO AnyPtr

||| Get the native type of a value.
|||
export %foreign "C:oracle_query_value_native_type,oracle-idris"
prim__queryValueNativeType : AnyPtr -> PrimIO Int32
