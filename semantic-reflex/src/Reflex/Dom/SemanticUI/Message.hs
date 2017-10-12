{-# LANGUAGE DuplicateRecordFields  #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE RecordWildCards        #-}
{-# LANGUAGE RecursiveDo            #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeApplications       #-}
{-# LANGUAGE TypeFamilies           #-}

-- | Semantic UI messages. Pure reflex implementation is provided.
-- https://semantic-ui.com/collections/messages.html
module Reflex.Dom.SemanticUI.Message
  (
  -- * Message
    Message (..)
  -- * Message type
  , MessageType (..)
  -- * Message result
  , MessageResult (..)
  -- * Message config
  , MessageConfig (..)
  ) where

import Control.Lens ((%~))
import Control.Monad ((<=<))
import Data.Default (Default(..))
import Data.Functor.Misc (WrapArg(..))
import Data.Maybe (isJust)
import Data.Proxy (Proxy(..))
import Data.Semigroup ((<>))
import Data.Text (Text)
import qualified GHCJS.DOM.Types as DOM
import qualified GHCJS.DOM.HTMLInputElement as Input
import Language.Javascript.JSaddle (liftJSM)
import Reflex
import Reflex.Dom.Core hiding (message, Message, MessageConfig)

import Reflex.Dom.SemanticUI.Common
import Reflex.Dom.SemanticUI.Icon
import Reflex.Dom.SemanticUI.Transition hiding (divClass)
import Reflex.Dom.SemanticUI.Header

data MessageType
  = ErrorMessage
  | NegativeMessage
  | PositiveMessage
  | SuccessMessage
  | WarningMessage
  | InfoMessage
  deriving (Eq, Show)

instance ToClassText MessageType where
  toClassText ErrorMessage = "error"
  toClassText NegativeMessage = "negative"
  toClassText PositiveMessage = "positive"
  toClassText SuccessMessage = "success"
  toClassText WarningMessage = "warning"
  toClassText InfoMessage = "info"

-- | Configuration of a message. Value and indeterminate are split into initial
-- and set events in order to logically disconnect them from their dynamic
-- return values in MessageResult.
data MessageConfig t m a b = MessageConfig
  { _header :: Maybe (Restrict Inline m a)
  -- ^ Message header content
  , _message :: Maybe (Restrict Inline m b)
  -- ^ Message content
  , _icon :: Maybe (Icon t)
  -- ^ Message icon
  , _dismissable :: Bool
  -- ^ Messages can be dismissable
  , _setHidden :: Event t Bool
  -- ^ Messages can be hidden

  , _floating :: Active t Bool
  -- ^ Messages can be floating (note: not the same as float: left|right)
  , _attached :: Active t (Maybe VerticalAttached)
  -- ^ Messages can be attached vertically
  , _compact :: Active t Bool
  -- ^ If the message should be compact
  , _messageType :: Active t (Maybe MessageType)
  -- ^ Message type (essentially more color choices)
  , _color :: Active t (Maybe Color)
  -- ^ Message color
  , _size :: Active t (Maybe Size)
  -- ^ Message size
  , _config :: ActiveElConfig t
  -- ^ Config
  }

instance Reflex t => Default (MessageConfig t m a b) where
  def = MessageConfig
    { _header = Nothing
    , _message = Nothing
    , _icon = Nothing
    , _dismissable = False
    , _setHidden = never

    , _floating = Static False
    , _attached = Static Nothing
    , _compact = Static False
    , _messageType = Static Nothing
    , _color = Static Nothing
    , _size = Static Nothing
    , _config = def
    }

-- | Make the message div classes from the configuration
messageConfigClasses :: Reflex t => MessageConfig t m a b -> Active t Classes
messageConfigClasses MessageConfig {..} = activeClasses
  [ Static $ Just "ui message"
  , boolClass "icon" $ Static $ isJust _icon
  , boolClass "floating" _floating
  , fmap toClassText <$> _attached
  , boolClass "compact" _compact
  , fmap toClassText <$> _messageType
  , fmap toClassText <$> _color
  , fmap toClassText <$> _size
  ]

-- | Result of running a message
data MessageResult t m a b = MessageResult
  { _header :: Maybe a
  -- ^ The header return value
  , _message :: Maybe b
  -- ^ The message return value
  , _icon :: Maybe (El t, Return t m (Icon t))
  -- ^ Icon result
  }

-- | Message UI Element. The minimum useful message only needs a label and a
-- default configuration.
data Message t m a b = Message
  { _config :: MessageConfig t m a b
  }

instance (t ~ t', m ~ m') => UI t' m' None (Message t m a b) where
  type Return t' m' (Message t m a b) = MessageResult t m a b
  ui' (Message config@MessageConfig{..}) = do

    let dismissIcon = domEvent Click . fst <$> unRestrict (ui' $ Icon "close" def)

    let content = do
          dismissed <- if _dismissable then dismissIcon else return never
          header <- traverse (divClass "header" `mapRestrict`) _header
          message <- traverse (el "p" `mapRestrict`) _message
          return (header, message, dismissed)

    rec
      hidden <- holdDyn False $ leftmost
        [ True <$ dismissed
        , _setHidden ]

      (divEl, (icon, (header, message, dismissed))) <-
        reRestrict $ elWithAnim' "div" (attrs hidden) $ do
          case _icon of
            Nothing -> (,) Nothing <$> reRestrict content
            Just icon -> do
              i <- unRestrict $ ui' icon
              c <- divClass "content" `mapRestrict` reRestrict content
              return (Just i, c)

    return $ (divEl, MessageResult
      { _header = header
      , _message = message
      , _icon = icon
      })

    where
      attrs hidden = _config <> def
        { _classes = addClassMaybe <$> (boolClass "hidden" $ Dynamic hidden) <*> messageConfigClasses config
        }