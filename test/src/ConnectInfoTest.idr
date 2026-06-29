module ConnectInfoTest

import Oracle
import System

export
username : String
username = "idris"

export
password : String
password = "idris"

export
host : String
host = "127.0.0.1"

export
port : Nat
port = 1521

export
service : String
service = "FREEPDB1"

||| Connection information for the Oracle integration test database.
|||
||| This configuration matches the Docker container created by `startup.sh`.
|||
||| Username:
||| * idris
|||
||| Password:
||| * idris
|||
||| Host:
||| * localhost
|||
||| Port:
||| * 1521
|||
||| Service:
||| * FREEPDB1
|||
export
connectinfo : ConnectInfo
connectinfo =
  MkConnectInfo
    username
    password
    host
    port
    service
