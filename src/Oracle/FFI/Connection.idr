module Oracle.FFI.Connection

||| Create a new Oracle connection.
|||
||| Parameters:
||| 1. Username
||| 2. Password
||| 3. Connect string
|||
||| Returns a raw dpiConn pointer.
|||
export %foreign "C:oracle_connect,oracle-idris"
prim__connect : String -> String -> String -> PrimIO AnyPtr

||| Release an Oracle connection.
|||
export %foreign "C:oracle_disconnect,oracle-idris"
prim__disconnect : AnyPtr -> PrimIO ()
