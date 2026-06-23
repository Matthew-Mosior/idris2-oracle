module Oracle.Internal.Either

||| Monadic composition for Oracle operations that return
||| `Either` values inside `IO`.
|||
||| If the first action succeeds, its result is passed to
||| the supplied continuation.
|||
||| If the first action fails with `Left`, the error is
||| propagated immediately and the continuation is not
||| executed.
|||
||| This function is useful for sequencing database
||| operations while automatically propagating
||| `OracleError` values without deeply nested
||| pattern matching.
|||
||| Example:
|||
||| ```idris
||| query conn sql params =
|||   withStatement conn sql $ \stmt =>
|||     bind stmt params `andThen` \_ =>
|||     execute stmt     `andThen` \_ =>
|||     fetchRaw stmt
||| ```
|||
||| This behaves similarly to `(>>=)` for
||| `Either e`, but operates on values of type
||| `IO (Either e a)`.
|||
export
andThen : IO (Either e a) -> (a -> IO (Either e b)) -> IO (Either e b)
andThen action f = do
  result <- action
  case result of
    Left err    =>
      pure (Left err)
    Right value =>
      f value

export infixl 1 >>==
||| Infix version of `andThen`.
|||
||| Allows sequencing Oracle operations using
||| monadic-style syntax.
|||
||| Example:
|||
||| ```idris
||| bind stmt params >>== \_ =>
||| execute stmt     >>== \_ =>
||| fetchRaw stmt
||| ```
|||
||| Equivalent to:
|||
||| ```idris
||| andThen (bind stmt params) (\_ =>
|||   andThen (execute stmt) (\_ =>
|||     fetchRaw stmt))
||| ```
|||
export
(>>==) : IO (Either e a) -> (a -> IO (Either e b)) -> IO (Either e b)
(>>==) = andThen
