{-# LANGUAGE OverloadedStrings #-}
module Data.Bits.ByteString
  ( bytestringAND
  , bytestringOR
  , bytestringXOR
  , bytestringComplement
  , bytestringShift
  , bytestringShiftR
  , bytestringShiftL
  , bytestringRotate
  , bytestringRotateR
  , bytestringRotateL
  , bytestringBitSize
  , bytestringBitSizeMaybe
  , bytestringIsSigned
  , bytestringTestBit
  , bytestringBit
  , bytestringPopCount
  ) where

import            Data.Bits
import qualified  Data.ByteString as B
import            Data.Word


bytestringAND :: B.ByteString -> B.ByteString -> B.ByteString
bytestringAND a b = B.pack $ B.zipWith (.&.) a b


bytestringOR :: B.ByteString -> B.ByteString -> B.ByteString
bytestringOR a b = B.pack $ B.zipWith (.|.) a b


bytestringXOR :: B.ByteString -> B.ByteString -> B.ByteString
bytestringXOR a b = B.pack $ B.zipWith xor a b


bytestringComplement :: B.ByteString -> B.ByteString
bytestringComplement = B.map complement


bytestringShift :: B.ByteString -> Int -> B.ByteString
bytestringShift x i
  | i < 0     = x `bytestringShiftR` (-i)
  | i > 0     = x `bytestringShiftL` i
  | otherwise = x


bytestringShiftR :: B.ByteString -> Int -> B.ByteString
bytestringShiftR bs 0 = bs
bytestringShiftR "" _ = B.empty
bytestringShiftR bs i =
    B.pack $ dropWhile (==0) $
      go (i `mod` 8) 0 (B.unpack bs)
  where
  go j w1 [] = []
  go j w1 (w2:wst) = (maskR j w1 w2) : go j w2 wst
  maskR i w1 w2 = (shiftL w1 (8-i)) .|. (shiftR w2 i)


bytestringShiftL :: B.ByteString -> Int -> B.ByteString
bytestringShiftL bs 0 = bs
bytestringShiftL "" _ = B.empty
bytestringShiftL bs i =
    B.pack $ dropWhile (==0)
      $ (go (i `mod` 8) 0 (B.unpack bs))
      ++ (replicate (i `div` 8) 0)
  where
  go j w1 [] = [shiftL w1 j]
  go j w1 (w2:wst) = (maskL j w1 w2) : go j w2 wst
  maskL i w1 w2 = (shiftL w1 i) .|. (shiftR w2 (8-i))


bytestringRotate :: B.ByteString -> Int -> B.ByteString
bytestringRotate x i
  | i < 0     = x `bytestringRotateR` (-i)
  | i > 0     = x `bytestringRotateL` i
  | otherwise = x


bytestringRotateR :: B.ByteString -> Int -> B.ByteString
bytestringRotateR bs 0 = bs
bytestringRotateR bs i
    | B.length bs == 0 = B.empty
    | B.length bs == 1 = B.singleton (rotateR (bs `B.index` 0) i)
    | B.length bs > 1 = do
      let shiftedWords =
            B.append
              (B.drop (nWholeWordsToShift i) bs)
              (B.take (nWholeWordsToShift i) bs)
      let tmpShiftedBits = (bytestringShiftR shiftedWords (i `mod` 8))
      let rotatedBits = (shiftL (B.last shiftedWords) (8 - (i `mod` 8))) .|. (B.head tmpShiftedBits)
      rotatedBits `B.cons` (B.tail tmpShiftedBits)
  where
  nWholeWordsToShift n =  (B.length bs - (n `div` 8))


bytestringRotateL :: B.ByteString -> Int -> B.ByteString
bytestringRotateL bs 0 = bs
bytestringRotateL bs i
    | B.length bs == 0 = B.empty
    | B.length bs == 1 = B.singleton (rotateL (bs `B.index` 0) i)
    | B.length bs > 1 = do
      let shiftedWords =
            B.append
              (B.take (nWholeWordsToShift i) bs)
              (B.drop (nWholeWordsToShift i) bs)
      let tmpShiftedBits = (bytestringShiftL shiftedWords (i `mod` 8))
      let rotatedBits = (shiftR (B.head shiftedWords) (8 - (i `mod` 8))) .|. (B.last tmpShiftedBits)
      (B.tail tmpShiftedBits) `B.snoc` rotatedBits
  where
  nWholeWordsToShift n = (B.length bs - (n `div` 8))


bytestringBitSize :: B.ByteString -> Int
bytestringBitSize x = 8 * B.length x


bytestringBitSizeMaybe :: B.ByteString -> Maybe Int
bytestringBitSizeMaybe x = Just (8 * B.length x)


bytestringIsSigned :: B.ByteString -> Bool
bytestringIsSigned x = False


bytestringTestBit :: B.ByteString -> Int -> Bool
bytestringTestBit x i = testBit (B.index x (B.length x - (i `div` 8) - 1)) (i `mod` 8)


bytestringBit :: Int -> B.ByteString
bytestringBit i = (bit $ mod i 8) `B.cons` (B.replicate (div i 8) (255 :: Word8))


bytestringPopCount :: B.ByteString -> Int
bytestringPopCount x = sum $ map popCount $ B.unpack x
