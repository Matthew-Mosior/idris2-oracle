module Oracle.Types.PoolConfig

import Oracle.Types.ConnectInfo

||| Configuration for an Oracle session pool.
|||
public export
record PoolConfig where
  constructor MkPoolConfig
  connectinfo : ConnectInfo
  minsessions : Nat
  maxsessions : Nat
  increment   : Nat
