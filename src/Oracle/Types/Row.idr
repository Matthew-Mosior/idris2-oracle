module Oracle.Types.Row

import Oracle.Types.BindParameter
import Oracle.Types.Error
import Oracle.Types.Value

public export
interface ToOracle a where
  toOracle : a -> OracleValue

public export
interface FromOracle a where
  fromOracle : OracleValue -> Either OracleError a

public export
interface ToRow a where
  toRow : a -> List BindParameter

public export
interface FromRow a where
  fromRow : List OracleValue -> Either OracleError a
