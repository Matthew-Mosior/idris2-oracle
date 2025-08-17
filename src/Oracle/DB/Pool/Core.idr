module Oracle.DB.Pool.Core

import Oracle.DB.Pool.Internal

import Data.C.Ptr

--------------------------------------------------------------------------------
--          Pool
--------------------------------------------------------------------------------

||| Create a session pool.
%foreign liboracle "dpiPool_create"
prim__dpiPoolCreate : AnyPtr -> String -> Bits32 -> String -> Bits32 -> String -> Bits32 -> AnyPtr -> AnyPtr -> AnyPtr -> Int

||| Create a session pool.
export
dpiCreatePool : IO Int
dpiCreatePool =
  primIO $
    prim__dpiPoolCreate (ptr)
                        (

||| Close a session pool.
%foreign liboracle "dpiPool_close_d"
prim__dpiPoolClose : AnyPtr -> AnyPtr -> Int

||| Acquire a connection from a session pool.
%foreign liboracle "dpiPool_acquireConnection"
prim__dpiAcquireConnection : AnyPtr -> String -> Bits32 -> String -> Bits32 -> AnyPtr -> AnyPtr -> Int

||| Release a reference to a pool.
||| A count of the references to the pool is maintained and when
||| this count reaches zero, the memory associated with the pool
||| is freed and the session pool is closed if that has not already
||| taken place using the function closePool.
%foreign liboracle "dpiPool_release"
prim__dpiPoolRelease : AnyPtr -> Int

||| Get the mode used for acquiring or getting connections from a session pool.
%foreign liboracle "dpiPool_getGetMode"
prim__dpiGetGetMode : AnyPtr -> AnyPtr -> Int

||| Set the mode used for acquiring or getting connections from a session pool.
%foreign liboracle "dpiPool_setGetMode_d"
prim__dpiSetGetMode : AnyPtr -> AnyPtr -> Int

||| Get the maximum lifetime a pooled session may exist.
||| Sessions in use will not be closed.
||| They become candidates for termination only when they are released back to the pool
||| and have existed for longer than the returned value.
||| Note that termination only occurs when the pool is accessed.
%foreign liboracle "dpiPool_getMaxLifetimeSession"
prim__dpiGetMaxLifetimeSession : AnyPtr -> AnyPtr -> Int

||| Set the maximum lifetime a pooled session may exist, in seconds.
||| Sessions in use will not be closed.
||| They become candidates for termination only when they are released back to the pool
||| and have existed for longer then the specified value.
||| Note that termination only occurs when the pool is accessed.
%foreign liboracle "dpi_setMaxLifetimeSession"
prim__dpiSetMaxLifetimeSession : AnyPtr -> Bits32 -> Int

||| Get the maximum sessions per shard.
||| This is used for balancing shards.
%foreign liboracle "dpiPool_getMaxSessionsPerShard"
prim__dpiGetMaxSessionsPerShard : AnyPtr -> AnyPtr -> Int

||| Set the maximum number of sessions per shard.
%foreign liboracle "dpiPool_setMaxSessionsPerShard"
prim__dpiSetMaxSessionsPerShard : AnyPtr -> Bits32 -> Int

||| Get the number of sessions in a pool that are open.
%foreign liboracle "dpiPool_getOpenCount"
prim__dpiGetOpenCount : AnyPtr -> AnyPtr -> Int

||| Get the number of sessions in a pool that are busy.
%foreign liboracle "dpiPool_getBusyCount"
prim__dpiGetBusyCount : AnyPtr -> Ptr Bits32 -> Int
