{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import Options.Applicative.Simple
import qualified Paths_latest_qtility_nix
import Qtility
import Run
import Types

main :: IO ()
main = do
  (options, ()) <-
    simpleOptions
      $(simpleVersion Paths_latest_qtility_nix.version)
      "Header for command line arguments"
      "Program description, also for command line arguments"
      ( Options
          <$> switch
            ( long "verbose"
                <> short 'v'
                <> help "Verbose output?"
            )
      )
      empty
  run options
