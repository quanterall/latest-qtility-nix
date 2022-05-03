{-# LANGUAGE TemplateHaskell #-}

module Types where

import Network.HTTP.Client (HasHttpManager (..), Manager)
import Qtility
import RIO.Process (HasProcessContext (..), ProcessContext)

-- | Command line arguments
newtype Options = Options
  { _optionsVerbose :: Bool
  }

data App = App
  { _appLogFunc :: !LogFunc,
    _appProcessContext :: !ProcessContext,
    _appOptions :: !Options,
    _appHttpManager :: !Manager
  }

foldMapM makeLenses [''Options, ''App]

instance HasLogFunc App where
  logFuncL = appLogFunc

instance HasProcessContext App where
  processContextL = appProcessContext

instance HasHttpManager App where
  getHttpManager = _appHttpManager
