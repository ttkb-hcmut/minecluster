module Main where

import Fudgets

main :: IO ()
main =
  fudlogue (shellF "Hello" $ labelF "Hello world!")
