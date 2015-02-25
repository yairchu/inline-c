{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
module Language.C.Inline.FunPtr
  ( mkFunPtr
  , peekFunPtr
  , uniqueFfiImportName
  ) where

import           Foreign.Ptr (FunPtr)
import qualified Language.Haskell.TH as TH
import qualified Language.Haskell.TH.Syntax as TH

------------------------------------------------------------------------
-- FFI wrappers

-- | @$('mkFunPtr' [t| 'CDouble' -> 'IO' 'CDouble' |] @ generates a foreign import
-- wrapper of type
--
-- @
-- ('CDouble' -> 'IO' 'CDouble') -> 'IO' ('FunPtr' ('CDouble' -> 'IO' 'CDouble'))
-- @
--
-- And invokes it.
mkFunPtr :: TH.TypeQ -> TH.ExpQ
mkFunPtr hsTy = do
  ffiImportName <- uniqueFfiImportName
  dec <- TH.forImpD TH.CCall TH.Safe "wrapper" ffiImportName [t| $(hsTy) -> IO (FunPtr $(hsTy)) |]
  TH.addTopDecls [dec]
  TH.varE ffiImportName

-- | @$('mkFunPtr' [t| 'CDouble' -> 'IO' 'CDouble' |])@ generates a foreign import
-- dynamic of type
--
-- @
-- 'FunPtr' ('CDouble' -> 'IO' 'CDouble') -> ('CDouble' -> 'IO' 'CDouble')
-- @
--
-- And invokes it.
peekFunPtr :: TH.TypeQ -> TH.ExpQ
peekFunPtr hsTy = do
  ffiImportName <- uniqueFfiImportName
  dec <- TH.forImpD TH.CCall TH.Safe "dynamic" ffiImportName [t| FunPtr $(hsTy) -> $(hsTy) |]
  TH.addTopDecls [dec]
  TH.varE ffiImportName

-- TODO absurdly, I need to 'newName' twice for things to work.  I found
-- this hack in language-c-inline.  Why is this?
uniqueFfiImportName :: TH.Q TH.Name
uniqueFfiImportName = TH.newName . show =<< TH.newName "inline_c_ffi"
