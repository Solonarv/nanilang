module Nani.Syntax.AST where

data Mod i = Mod
  { modBody :: Expr i
  }
  deriving (Eq, Show)

data Expr i
  = Var i
  | TyAnn (Expr i) (Expr i)
  | App (Expr i) [Expr i]
  | Lam i (Expr i)
  | Let (Expr i) (Expr i)
  | Rec (Assocs i)
  | VisOverride (Expr i)
  | Infer
  | FunTy (Expr i) (Expr i)
  | ForallTy [TyVarBndr i] (Expr i)
  | Literal (Lit i)
  deriving (Eq, Show)

-- Oh boy we sure have a lot of those!
data Lit i
  = LitInt Integer
  | LitFrac Rational
  | LitChar Char
  | LitStr String
  | LitLabel String
  | LitArr [Expr i]
  | LitHArr [Expr i]
  | LitMap (Assocs i)
  | LitSet [Expr i]
  | LitHSet [Expr i]
  | LitRec (Assocs i)
  deriving (Eq, Show)

data Assocs i = Assocs [(String, Expr i)]

data TyVarBndr i
 = TyvarBare i
 | TyvarTyped (Expr i) i