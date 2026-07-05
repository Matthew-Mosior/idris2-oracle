module Oracle.Types.ConnectInfo

import Derive.Prelude

%language ElabReflection

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

%runElab derive "ConnectInfo" [Eq,Ord,Show]
