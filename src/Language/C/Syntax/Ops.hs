{-# LANGUAGE DeriveDataTypeable #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Language.C.Syntax.Ops
-- Copyright   :  (c) 2008 Benedikt Huber
-- License     :  BSD-style
-- Maintainer  : benedikt.huber@gmail.com
-- Stability   : experimental
-- Portability : ghc
--
-- Unary, binary and asssignment operators. Exported via AST.
-----------------------------------------------------------------------------
module Language.C.Syntax.Ops (
-- * Assignment operators
CAssignOp(..),
assignBinop,
-- * Binary operators
CBinaryOp(..),
isCmpOp,
isPtrOp,
isBitOp,
isLogicOp,
-- * Unary operators
CUnaryOp(..),
isEffectfulOp
)
where
import Data.Generics
-- | C assignment operators (K&R A7.17)
data CAssignOp = CAssignOp
               | CMulAssOp
               | CDivAssOp
               | CRmdAssOp              -- ^ remainder and assignment
               | CAddAssOp
               | CSubAssOp
               | CShlAssOp
               | CShrAssOp
               | CAndAssOp
               | CXorAssOp
               | COrAssOp
               deriving (Eq, Ord,Data,Typeable)
instance Show CAssignOp where
  show CAssignOp = "="
  show CMulAssOp = "*="
  show CDivAssOp = "/="
  show CRmdAssOp = "%="
  show CAddAssOp = "+="
  show CSubAssOp = "-="
  show CShlAssOp = "<<="
  show CShrAssOp = ">>="
  show CAndAssOp = "&="
  show CXorAssOp = "^="
  show COrAssOp  = "|="

assignBinop :: CAssignOp -> CBinaryOp
assignBinop CAssignOp = error "direct assignment has no binary operator"
assignBinop CMulAssOp = CMulOp
assignBinop CDivAssOp = CDivOp
assignBinop CRmdAssOp = CRmdOp
assignBinop CAddAssOp = CAddOp
assignBinop CSubAssOp = CSubOp
assignBinop CShlAssOp = CShlOp
assignBinop CShrAssOp = CShrOp
assignBinop CAndAssOp = CAndOp
assignBinop CXorAssOp = CXorOp
assignBinop COrAssOp  = COrOp

-- | C binary operators (K&R A7.6-15)
--
data CBinaryOp = CMulOp
               | CDivOp
               | CRmdOp                 -- ^ remainder of division
               | CAddOp
               | CSubOp
               | CShlOp                 -- ^ shift left
               | CShrOp                 -- ^ shift right
               | CLeOp                  -- ^ less
               | CGrOp                  -- ^ greater
               | CLeqOp                 -- ^ less or equal
               | CGeqOp                 -- ^ greater or equal
               | CEqOp                  -- ^ equal
               | CNeqOp                 -- ^ not equal
               | CAndOp                 -- ^ bitwise and
               | CXorOp                 -- ^ exclusive bitwise or
               | COrOp                  -- ^ inclusive bitwise or
               | CLndOp                 -- ^ logical and
               | CLorOp                 -- ^ logical or
               deriving (Eq,Ord,Data,Typeable)
instance Show CBinaryOp where
  show CMulOp = "*"
  show CDivOp = "/"
  show CRmdOp = "%"
  show CAddOp = "+"
  show CSubOp = "-"
  show CShlOp = "<<"
  show CShrOp = ">>"
  show CLeOp  = "<"
  show CGrOp  = ">"
  show CLeqOp = "<="
  show CGeqOp = ">="
  show CEqOp  = "=="
  show CNeqOp = "!="
  show CAndOp = "&"
  show CXorOp = "^"
  show COrOp  = "|"
  show CLndOp = "&&"
  show CLorOp = "||"

isCmpOp :: CBinaryOp -> Bool
isCmpOp op = op `elem` [ CLeqOp, CGeqOp, CLeOp, CGrOp, CEqOp, CNeqOp ]

isPtrOp :: CBinaryOp -> Bool
isPtrOp op = op `elem` [ CAddOp, CSubOp ]

isBitOp :: CBinaryOp -> Bool
isBitOp op = op `elem` [ CShlOp, CShrOp, CAndOp, COrOp, CXorOp ]

isLogicOp :: CBinaryOp -> Bool
isLogicOp op = op `elem` [ CLndOp, CLorOp ]

-- | C unary operator (K&R A7.3-4)
--
data CUnaryOp = CPreIncOp               -- ^ prefix increment operator
              | CPreDecOp               -- ^ prefix decrement operator
              | CPostIncOp              -- ^ postfix increment operator
              | CPostDecOp              -- ^ postfix decrement operator
              | CAdrOp                  -- ^ address operator
              | CIndOp                  -- ^ indirection operator
              | CPlusOp                 -- ^ prefix plus
              | CMinOp                  -- ^ prefix minus
              | CCompOp                 -- ^ one's complement
              | CNegOp                  -- ^ logical negation
              deriving (Eq,Ord,Data,Typeable)
instance Show CUnaryOp where
  show CPreIncOp  = "++"
  show CPreDecOp  = "--"
  show CPostIncOp = "++"
  show CPostDecOp = "--"
  show CAdrOp     = "&"
  show CIndOp     = "*"
  show CPlusOp    = "+"
  show CMinOp     = "-"
  show CCompOp    = "~"
  show CNegOp     = "!"

isEffectfulOp :: CUnaryOp -> Bool
isEffectfulOp op = op `elem` [ CPreIncOp, CPreDecOp, CPostIncOp, CPostDecOp ]
