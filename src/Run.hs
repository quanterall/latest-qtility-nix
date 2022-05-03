module Run (run) where

import Codec.Archive.Zip.Conduit.UnZip (ZipEntry (..), unZipStream)
import Conduit
import Network.HTTP.Client.Conduit
import Network.HTTP.Client.TLS (newTlsManager)
import Qtility
import RIO.Directory (createDirectoryIfMissing, doesFileExist)
import RIO.FilePath (takeDirectory)
import qualified RIO.List.Partial as PartialList
import RIO.Process (mkDefaultProcessContext)
import qualified RIO.Text as Text
import Types

run :: Options -> IO ()
run options = do
  lo <- logOptionsHandle stderr (options ^. optionsVerbose)
  pc <- mkDefaultProcessContext
  manager <- newTlsManager
  withLogFunc lo $ \lf ->
    let app =
          App
            { _appLogFunc = lf,
              _appProcessContext = pc,
              _appOptions = options,
              _appHttpManager = manager
            }
     in runRIO app runApp

runApp :: RIO App ()
runApp = do
  downloadRepositoryZipFile

downloadRepositoryZipFile :: RIO App ()
downloadRepositoryZipFile = do
  runConduitRes $
    httpSource "https://github.com/quanterall/qtility/archive/refs/heads/main.zip" responseBody
      .| void unZipStream
      .| streamEntriesBeginningWith "qtility-main/nix/sources"
      .| mapM_C writeSourceFile
      .| sinkNull
  where
    streamEntriesBeginningWith prefix = do
      headers <- takeWhileC isLeft .| sinkList
      if null headers
        then pure ()
        else do
          let lastHeader = headers & PartialList.last & fromLeft' & zipEntryName'
          if prefix `Text.isPrefixOf` lastHeader
            then do
              dataChunks <- rights <$> (takeWhileC isRight .| sinkList)
              if null dataChunks
                then error $ "Empty data chunks for header: " <> show lastHeader
                else yield (lastHeader, mconcat dataChunks)
              streamEntriesBeginningWith prefix
            else do
              dropWhileC isRight
              streamEntriesBeginningWith prefix
    writeSourceFile (name, content) = do
      let filename = name & Text.dropPrefix "qtility-main/" & Text.unpack
      createDirectoryIfMissing True $ takeDirectory filename
      unlessM (doesFileExist filename) $ writeFileUtf8 filename (decodeUtf8Lenient content)

fromLeft' :: Either l r -> l
fromLeft' (Left l) = l
fromLeft' _ = error "fromLeft' called on Right"

zipEntryName' :: ZipEntry -> Text
zipEntryName' ZipEntry {zipEntryName = Left n} = n
zipEntryName' ZipEntry {zipEntryName = Right n} = decodeUtf8Lenient n
