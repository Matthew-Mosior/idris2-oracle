module Oracle.Types.ConnectInfo

||| Connection information required to establish
||| a connection to an Oracle database.
|||
public export
record ConnectInfo where
  constructor MkConnectInfo
  username : String
  password : String
  host     : String
  port     : Nat
  service  : String
