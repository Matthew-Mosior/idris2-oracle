module Oracle.DB.Pool.Types

import Data.C.Array

--------------------------------------------------------------------------------
-- Pool
--------------------------------------------------------------------------------

export
record DPIEnv where
  constructor MkDPIEnv
  dpienv_context : Ptr DPIContext
  dpienv_mutex : DPIMutexType
  dpienv_encoding : CIArray 100 Char
  dpienv_maxbytespercharacter : Int32
--  dpienv_charsetid : 

export
record DPITypeDef where
  constructor MkDPITypeDef
  dpitypedef_name : Ptr Char
  dpitypedef_size : Bits64
  dpitypedef_checkint : Bits32
  dpitypedef_freeproc : AnyPtr

export
record DPIPool where
  constructor MkDPIPool
  dpipool_typedef : Ptr DPITypeDef
  dpipool_checkint : Bits32
  dpipool_refcount : Bits64
  dpipool_env : Ptr DPIEnv
