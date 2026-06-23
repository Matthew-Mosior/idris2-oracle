module Oracle.FFI.Bind

%default total

||| Bind a NULL value to a named parameter.
|||
export %foreign "C:oracle_bind_null"
prim__bindNull : AnyPtr -> String -> PrimIO Int32

||| Bind a String value to a named parameter.
|||
export %foreign "C:oracle_bind_string"
prim__bindString : AnyPtr -> String -> String -> PrimIO Int32

||| Bind an Int64 value to a named parameter.
|||
export %foreign "C:oracle_bind_int64"
prim__bindInt64 : AnyPtr -> String -> Int64 -> PrimIO Int32

||| Bind a Double value to a named parameter.
|||
export %foreign "C:oracle_bind_double"
prim__bindDouble : AnyPtr -> String -> Double -> PrimIO Int32

||| Bind a Bool value to a named parameter.
|||
||| The C layer should map 0/1 into the Oracle boolean binding.
|||
export %foreign "C:oracle_bind_bool"
prim__bindBool : AnyPtr -> String -> Int32 -> PrimIO Int32

||| Bind a CLOB value.
|||
export %foreign "C:oracle_bind_clob"
prim__bindClob : AnyPtr -> String -> String -> PrimIO Int32

||| Bind a BLOB value.
|||
export %foreign "C:oracle_bind_blob"
prim__bindBlob : AnyPtr -> String -> String -> PrimIO Int32
