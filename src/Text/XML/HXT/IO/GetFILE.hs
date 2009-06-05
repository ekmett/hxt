-- ------------------------------------------------------------

{- |
   Module     : Text.XML.HXT.IO.GetFILE
   Copyright  : Copyright (C) 2008 Uwe Schmidt
   License    : MIT

   Maintainer : Uwe Schmidt (uwe@fh-wedel.de)
   Stability  : stable
   Portability: portable

   The GET method for file protocol

-}

-- ------------------------------------------------------------

module Text.XML.HXT.IO.GetFILE
    ( getStdinCont
    , getCont
    )

where

import qualified Data.ByteString        as B
import qualified Data.ByteString.Char8  as C

import           System.IO		( IOMode(..)
					, openFile
					  -- , getContents  is defined in the prelude
					, hGetContents
					)

import           System.IO.Error	( ioeGetErrorString
					, try
					)

import           System.Directory	( doesFileExist
					, getPermissions
					, readable
					)
import 		 Text.XML.HXT.DOM.XmlKeywords

-- ------------------------------------------------------------

getStdinCont		:: Bool -> IO (Either ([(String, String)], String)
				              String)
getStdinCont strictInput
    = do
      c <- try ( if strictInput
		 then do
		      cb <- B.getContents
		      return  (C.unpack cb)
		 else getContents
	       )
      return (either readErr Right c)
    where
    readErr e
	= Left ( [ (transferStatus,  "999")
		 , (transferMessage, msg)
		 ]
	       , msg
	       )
	  where
	  msg = "stdin read error: " ++ es
	  es  = ioeGetErrorString e

getCont		:: Bool -> String -> IO (Either ([(String, String)], String)
					        String)
getCont strictInput source
    = do			-- preliminary
      exists <- doesFileExist source'
      if not exists
	 then return $ fileErr "file not found"
	 else do
	      perm <- getPermissions source'
	      if not (readable perm)
	         then return $ fileErr "file not readable"
	         else do
		      c <- try ( if strictInput
				 then do
				      cb <- B.readFile source
				      return (C.unpack cb)
				 else do
				      h <- openFile source' ReadMode
				      hGetContents h
			       )
		      return (either readErr Right c)
    where

    -- please NO call of unEscapeString for file names, NOT: source' = drivePath . unEscapeString $ source
    source' = drivePath $ source
    readErr e
	= fileErr (ioeGetErrorString e)
    fileErr msg0
	= Left ( [ (transferStatus,  "999")
		 , (transferMessage, msg)
		 ]
	       , msg
	       )
	  where
	  msg = "file read error: " ++ show msg0 ++ " when accessing " ++ show source'

    -- remove leading / if file starts with windows drive letter, e.g. /c:/windows -> c:/windows
    drivePath ('/' : file@(d : ':' : _more))
	| d `elem` ['A'..'Z'] || d `elem` ['a'..'z']
	    = file
    drivePath file
	= file


-- ------------------------------------------------------------
