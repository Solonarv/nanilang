module Nani.Term where

data Term
  = PiT [VarBndr] Term

data VarBndr = VarBndr