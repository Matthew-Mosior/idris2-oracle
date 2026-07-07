module Oracle.FFI.Bind

%default total

||| Bind a NULL value to a named parameter.
|||
export %foreign "C:oracle_bind_null,oracle-idris"
prim__bindNull : AnyPtr -> String -> PrimIO Int32

||| Bind a String value to a named parameter.
|||
export %foreign "C:oracle_bind_string,oracle-idris"
prim__bindString : AnyPtr -> String -> String -> PrimIO Int32

||| Bind an Int64 value to a named parameter.
|||
export %foreign "C:oracle_bind_int64,oracle-idris"
prim__bindInt64 : AnyPtr -> String -> Int64 -> PrimIO Int32

||| Bind a Double value to a named parameter.
|||
export %foreign "C:oracle_bind_double,oracle-idris"
prim__bindDouble : AnyPtr -> String -> Double -> PrimIO Int32

||| Bind a Bool value to a named parameter.
|||
||| The C layer should map 0/1 into the Oracle boolean binding.
|||
export %foreign "C:oracle_bind_bool,oracle-idris"
prim__bindBool : AnyPtr -> String -> Int32 -> PrimIO Int32

||| Bind a CLOB value.
|||
export %foreign "C:oracle_bind_clob,oracle-idris"
prim__bindClob : AnyPtr -> String -> String -> PrimIO Int32

||| Bind a BLOB value.
|||
export %foreign "C:oracle_bind_blob,oracle-idris"
prim__bindBlob : AnyPtr -> String -> String -> PrimIO Int32

||| Bind an Oracle TIMESTAMP value to a named statement parameter.
|||
export %foreign "C:oracle_bind_timestamp,oracle-idris"
prim__bindTimestamp : AnyPtr -> String -> Int16 -> Int8 -> Int8 -> Int8 -> Int8 -> Int8 -> Int32 -> PrimIO Int32

||| Bind an Oracle TIMESTAMP WITH TIME ZONE value.
|||
export %foreign "C:oracle_bind_timestamp_tz,oracle-idris"
prim__bindTimestampTZ : AnyPtr -> String -> Int16 -> Int8 -> Int8 -> Int8 -> Int8 -> Int8 -> Int32 -> Int8 -> Int8 -> PrimIO Int32

||| Bind an Oracle INTERVAL YEAR TO MONTH value.
|||
export %foreign "C:oracle_bind_interval_ym,oracle-idris"
prim__bindIntervalYM : AnyPtr -> String -> Int32 -> Int32 -> PrimIO Int32

||| Bind an Oracle INTERVAL DAY TO SECOND value.
|||
export %foreign "C:oracle_bind_interval_ds,oracle-idris"
prim__bindIntervalDS : AnyPtr -> String -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Int32
