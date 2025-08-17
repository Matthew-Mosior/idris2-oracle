module Oracle.FFI.Utility

import System.FFI

public export
liboracle :  String
          -> String
liboracle fn = "C:" ++ fn ++ ", liboracle-idris"

export
%foreign liboracle "string_value"
prim__string_value : Ptr String -> String
