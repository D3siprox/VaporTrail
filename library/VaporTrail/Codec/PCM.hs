module VaporTrail.Codec.PCM (pcms16le) where

import Data.Bits
import Data.Int
import Data.Machine
import Data.Word
import VaporTrail.Codec.Type

clip :: Float -> Float
clip sample = min 1 (max (-1) sample)

toInt16 :: Float -> Int16
toInt16 sample =
  if sample < 0
    then floor (32768 * clip sample)
    else floor (32767 * clip sample)

fromInt16 :: Int16 -> Float
fromInt16 sample =
  if sample < 0
    then fromIntegral sample / 32768
    else fromIntegral sample / 32767

pcms16leEncode :: Process Float Word8
pcms16leEncode =
  repeatedly $ do
    input <- await
    let sample = toInt16 input
        lo = fromIntegral (sample .&. 0xFF) :: Word8
        hi = fromIntegral (shiftR sample 8 .&. 0xFF) :: Word8
    yield lo
    yield hi

pcms16leDecode :: Process Word8 Float
pcms16leDecode =
  repeatedly $ do
    l <- await
    h <- await
    let lo = fromIntegral l :: Int16
        hi = fromIntegral h :: Int16
        sample = lo .|. shiftL hi 8
    yield (fromInt16 sample)

pcms16le :: Codec Float Word8
pcms16le = Codec {codecEnc = pcms16leEncode, codecDec = pcms16leDecode}
