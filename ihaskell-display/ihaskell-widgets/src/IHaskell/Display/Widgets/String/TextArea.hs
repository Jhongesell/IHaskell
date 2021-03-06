{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module IHaskell.Display.Widgets.String.TextArea
  ( -- * The TextArea Widget
    TextArea
    -- * Constructor
  , mkTextArea
  ) where

-- To keep `cabal repl` happy when running from the ihaskell repo
import           Prelude

import           Control.Monad (void)
import           Data.Aeson
import           Data.IORef (newIORef)
import           Data.Vinyl (Rec(..), (<+>))

import           IHaskell.Display
import           IHaskell.Eval.Widgets
import           IHaskell.IPython.Message.UUID as U

import           IHaskell.Display.Widgets.Types
import           IHaskell.Display.Widgets.Common

-- | A 'TextArea' represents a Textarea widget from IPython.html.widgets.
type TextArea = IPythonWidget 'TextAreaType

-- | Create a new TextArea widget
mkTextArea :: IO TextArea
mkTextArea = do
  -- Default properties, with a random uuid
  wid <- U.random
  let strAttrs = defaultStringWidget "TextareaView" "TextareaModel"
      wgtAttrs = (ChangeHandler =:: return ()) :& RNil
      widgetState = WidgetState $ strAttrs <+> wgtAttrs

  stateIO <- newIORef widgetState

  let widget = IPythonWidget wid stateIO

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen widget $ toJSON widgetState

  -- Return the widget
  return widget

instance IHaskellDisplay TextArea where
  display b = do
    widgetSendView b
    return $ Display []

instance IHaskellWidget TextArea where
  getCommUUID = uuid
  comm widget val _ =
    case nestedObjectLookup val ["sync_data", "value"] of
      Just (String value) -> do
        void $ setField' widget StringValue value
        triggerChange widget
      _ -> pure ()
