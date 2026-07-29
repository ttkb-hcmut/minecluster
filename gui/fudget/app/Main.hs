module Main where

import Fudgets

main :: IO ()
main =
  fudlogue (shellF "Hello" (
    stringF >==< absF (stateSP "") >==< la
  ))

la :: F Click (String -> String)
la = const (++"wow") >^=< buttonF "sd"

stateSP :: state -> SP (state->state) state
stateSP =
  mapAccumlSP (\ acc f -> let newv = f acc in (newv, newv))
