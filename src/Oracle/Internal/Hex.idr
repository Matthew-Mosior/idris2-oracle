module Oracle.Internal.Hex

import Data.Bits

%default total

||| Convert a four-bit hexadecimal digit into its uppercase character
||| representation.
|||
||| Values 0 through 15 are mapped to `'0'` through `'9'` and `'A'`
||| through `'F'`.
|||
||| Values greater than 15 are treated as 15 and therefore map to `'F'`.
|||
export
hexDigit : Bits8 -> Char
hexDigit n =
  case n of
    0  => '0'
    1  => '1'
    2  => '2'
    3  => '3'
    4  => '4'
    5  => '5'
    6  => '6'
    7  => '7'
    8  => '8'
    9  => '9'
    10 => 'A'
    11 => 'B'
    12 => 'C'
    13 => 'D'
    14 => 'E'
    _  => 'F'

||| Encode a single byte as a two-character uppercase hexadecimal String.
|||
||| The high four bits are encoded first, followed by the low four bits.
|||
||| For example:
|||
||| ```text
||| 0x00 -> "00"
||| 0x2A -> "2A"
||| 0xFF -> "FF"
||| ```
|||
export
hexByte : Bits8 -> String
hexByte byte =
  pack
    [ hexDigit (byte `shiftR` 4)
    , hexDigit (byte .&. 0x0F)
    ]

||| Encode a list of bytes as an uppercase hexadecimal String.
|||
||| Each byte is represented by exactly two hexadecimal characters, so the
||| resulting String has twice as many characters as the input has bytes.
|||
||| This representation is safe for transporting arbitrary binary data across
||| String-based FFI boundaries because the resulting value contains only
||| ASCII hexadecimal characters.
|||
||| For example:
|||
||| ```text
||| [0x00, 0xFF, 0x01, 0x80, 0x41, 0x42]
|||     -> "00FF01804142"
||| ```
|||
export
hexEncode : List Bits8 -> String
hexEncode =
  concatMap hexByte

||| Decode a hexadecimal character into its four-bit numeric value.
|||
||| Both uppercase and lowercase hexadecimal characters are accepted.
|||
export
hexValue : Char -> Maybe Bits8
hexValue '0' = Just 0
hexValue '1' = Just 1
hexValue '2' = Just 2
hexValue '3' = Just 3
hexValue '4' = Just 4
hexValue '5' = Just 5
hexValue '6' = Just 6
hexValue '7' = Just 7
hexValue '8' = Just 8
hexValue '9' = Just 9
hexValue 'A' = Just 10
hexValue 'B' = Just 11
hexValue 'C' = Just 12
hexValue 'D' = Just 13
hexValue 'E' = Just 14
hexValue 'F' = Just 15
hexValue 'a' = Just 10
hexValue 'b' = Just 11
hexValue 'c' = Just 12
hexValue 'd' = Just 13
hexValue 'e' = Just 14
hexValue 'f' = Just 15
hexValue _   = Nothing

||| Decode two hexadecimal characters into a single byte.
|||
export
hexPair : Char -> Char -> Maybe Bits8
hexPair hi lo = do
  hi' <- hexValue hi
  lo' <- hexValue lo
  pure $ (hi' `shiftL` 4) .|. lo'

||| Decode an uppercase or lowercase hexadecimal String into bytes.
|||
||| Returns Nothing if the String has an odd number of characters or contains
||| any non-hexadecimal character.
|||
export
hexDecode : String -> Maybe (List Bits8)
hexDecode str =
  go (unpack str)
  where
    go : List Char -> Maybe (List Bits8)
    go [] = Just []
    go (hi :: lo :: rest) = do
      byte <- hexPair hi lo
      bytes <- go rest
      pure (byte :: bytes)
    go [_] = Nothing
