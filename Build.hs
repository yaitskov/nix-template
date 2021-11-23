module Main
  ( main,
  )
where

-------------------------------------------------------------------------------

import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Development.Shake
import Development.Shake.Config
import Development.Shake.FilePath
import System.Process (system)

-------------------------------------------------------------------------------

main :: IO ()
main = shakeArgs shakeOptions {shakeFiles = "_build"} $ do
  usingConfigFile "build.config"

  phony "repl" $ do
    need ["build"]
    -- Interactive commands aren't designed to work with cmd: https://github.com/ndmitchell/shake/issues/728
    liftIO $ void $ system "cabal repl"

  phony "build" $ do
    cmd_ "hpack"
    had <- getConfig "haddock"
    if had == Just "true"
      then cmd "cabal" ["build", "--haddock-all"]
      else cmd "cabal" ["build"]

  phony "docs" $
    cmd "cabal" ["haddock"]

  phony "examples" $ do
    need ["build"]
    mainFiles <- getDirectoryFiles "examples" ["//Main.hs"]
    need
      [ "_build/examples/" </> dropTrailingPathSeparator (dropFileName mainFile)
        | mainFile <- mainFiles
      ]

  phony "cleanup" $
    removeFilesAfter
      "examples"
      [ "//*.dyn_hi",
        "//*.dyn_o",
        "//*.hi",
        "//*.o"
      ]

  phony "clean" $ do
    removeFilesAfter "_build" ["//*"]
    need ["cleanup"]

  phony "lint" $ do
    cmd "pre-commit" ["run", "--hook-stage", "manual", "--color", "always"]

  "_build/examples/*" %> \out -> do
    -- examples depend on main library code
    src <- getDirectoryFiles "" ["src//*.hs"]
    need src

    let execName = takeFileName out
    let dir = "examples" </> execName
    srcFiles <- getDirectoryFiles dir ["//*.hs"]
    let mainFile = dir </> "Main.hs"
    need [dir </> f | f <- srcFiles]
    cmd
      "cabal"
      [ "exec",
        "--",
        "ghc",
        "--make",
        "-o",
        out,
        "-iexamples",
        "-rtsopts",
        "-threaded",
        mainFile
      ]

  want ["build", "examples", "cleanup"]
