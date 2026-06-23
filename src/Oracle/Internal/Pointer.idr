module Oracle.Internal.Pointer

||| Internal connection handle.
|||
||| Wraps a raw dpiConn pointer.
|||
public export
record Connection where
  constructor MkConnection
  ptr : AnyPtr

||| Internal prepared statement handle.
|||
public export
record Statement where
  constructor MkStatement
  ptr : AnyPtr

||| Internal session pool handle.
|||
public export
record Pool where
  constructor MkPool
  ptr : AnyPtr
