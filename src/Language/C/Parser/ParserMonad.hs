-----------------------------------------------------------------------------
-- |
-- Module      :  Language.C.Toolkit.ParserMonad
-- Copyright   :  (c) [1999..2004] Manuel M T Chakravarty
--                (c) 2005-2007 Duncan Coutts
-- License     :  BSD-style
-- Maintainer  :  benedikt.huber@gmail.com
-- Portability :  portable 
--
-- Monad for the C lexer and parser
--
--  This monad has to be usable with Alex and Happy. Some things in it are
--  dictated by that, eg having to be able to remember the last token.
--
--  The monad also provides a unique name supply (via the Names module)
--
--  For parsing C we have to maintain a set of identifiers that we know to be
--  typedef'ed type identifiers. We also must deal correctly with scope so we
--  keep a list of sets of identifiers so we can save the outer scope when we
--  enter an inner scope.
module Language.C.Parser.ParserMonad ( 
  P, 
  execParser,
  failP,
  getNewName,        -- :: P Name
  addTypedef,        -- :: Ident -> P ()
  shadowTypedef,     -- :: Ident -> P ()
  isTypeIdent,       -- :: Ident -> P Bool
  enterScope,        -- :: P ()
  leaveScope,        -- :: P ()
  setPos,            -- :: Position -> P ()
  getPos,            -- :: P Position
  getInput,          -- :: P String
  setInput,          -- :: String -> P ()
  getLastToken,      -- :: P CToken
  setLastToken,      -- :: CToken -> P ()
  ) where

import Language.C.Toolkit.Position  (Position(..))
import Language.C.Toolkit.Errors    (interr)
import Language.C.Toolkit.Names     (Name)
import Language.C.Toolkit.Idents    (Ident)

import Data.Set  (Set)
import qualified Data.Set as Set (fromList, insert, member, delete)

import Language.C.Parser.Tokens (CToken)

data ParseResult a
  = POk !PState a
  | PFailed [String] Position   -- The error message and position

data PState = PState { 
        curPos     :: !Position,        -- position at current input location
        curInput   :: !String,          -- the current input
        prevToken  ::  CToken,          -- the previous token
        namesupply :: ![Name],          -- the name unique supply
        tyidents   :: !(Set Ident),     -- the set of typedef'ed identifiers
        scopes     :: ![Set Ident]      -- the tyident sets for outer scopes
     }

newtype P a = P { unP :: PState -> ParseResult a }

instance Monad P where
  return = returnP
  (>>=) = thenP
  fail m = getPos >>= \pos -> failP pos [m]

execParser :: P a -> String -> Position -> [Ident] -> [Name]
           -> Either a ([String], Position)
execParser (P parser) input pos builtins names =
  case parser initialState of
    POk _ result -> Left result
    PFailed message errpos -> Right (message, errpos)
  where initialState = PState {
          curPos = pos,
          curInput = input,
          prevToken = interr "CLexer.execParser: Touched undefined token!",
          namesupply = names,
          tyidents = Set.fromList builtins,
          scopes   = []
        }

{-# INLINE returnP #-}
returnP :: a -> P a
returnP a = P $ \s -> POk s a

{-# INLINE thenP #-}
thenP :: P a -> (a -> P b) -> P b
(P m) `thenP` k = P $ \s ->
        case m s of
                POk s' a        -> (unP (k a)) s'
                PFailed err pos -> PFailed err pos

failP :: Position -> [String] -> P a
failP pos msg = P $ \_ -> PFailed msg pos

getNewName :: P Name
getNewName = P $ \s@PState{namesupply=(n:ns)} -> POk s{namesupply=ns} n

setPos :: Position -> P ()
setPos pos = P $ \s -> POk s{curPos=pos} ()

getPos :: P Position
getPos = P $ \s@PState{curPos=pos} -> POk s pos

addTypedef :: Ident -> P ()
addTypedef ident = (P $ \s@PState{tyidents=tyids} ->
                             POk s{tyidents = ident `Set.insert` tyids} ())

shadowTypedef :: Ident -> P ()
shadowTypedef ident = (P $ \s@PState{tyidents=tyids} ->
                             -- optimisation: mostly the ident will not be in
                             -- the tyident set so do a member lookup to avoid
                             --  churn induced by calling delete
                             POk s{tyidents = if ident `Set.member` tyids
                                                then ident `Set.delete` tyids
                                                else tyids } ())

isTypeIdent :: Ident -> P Bool
isTypeIdent ident = P $ \s@PState{tyidents=tyids} ->
                             POk s $! Set.member ident tyids

enterScope :: P ()
enterScope = P $ \s@PState{tyidents=tyids,scopes=ss} ->
                     POk s{scopes=tyids:ss} ()

leaveScope :: P ()
leaveScope = P $ \s@PState{scopes=ss} ->
                     case ss of
                       []             -> interr "leaveScope: already in global scope"
                       (tyids:ss') -> POk s{tyidents=tyids, scopes=ss'} ()

getInput :: P String
getInput = P $ \s@PState{curInput=i} -> POk s i

setInput :: String -> P ()
setInput i = P $ \s -> POk s{curInput=i} ()

getLastToken :: P CToken
getLastToken = P $ \s@PState{prevToken=tok} -> POk s tok

setLastToken :: CToken -> P ()
setLastToken tok = P $ \s -> POk s{prevToken=tok} ()