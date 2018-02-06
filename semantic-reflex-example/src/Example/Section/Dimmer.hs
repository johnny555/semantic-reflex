{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE GADTs                #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE QuasiQuotes          #-}
{-# LANGUAGE RecursiveDo          #-}
{-# LANGUAGE RecordWildCards      #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TemplateHaskell      #-}

module Example.Section.Dimmer where

import Control.Lens
import Control.Monad ((<=<))
import Reflex.Dom.SemanticUI
import Reflex.Dom.Core (text)

import Example.QQ
import Example.Common

dimmers :: forall t m. MonadWidget t m => Section t m
dimmers = Section "Dimmer" (text "A dimmers hides distractions to focus attention on particular content") $ do

  hscode $ $(printDefinition id stripParens ''DimmerConfig)

  pageHeader H3 def $ text "Types"

  mkExample "Dimmer" (def
    & subtitle ?~ text "A standard dimmer")
    [example|
  evt <- button def $ text "Toggle"

  segment def $ do
    header def $ text "Some Content"
    paragraph $ text $ "Suspendisse hendrerit justo id dignissim maximus. Ut maximus eu arcu sit amet egestas. Aenean et dictum felis. Ut rhoncus ipsum non luctus scelerisque. Proin pellentesque sed mauris efficitur aliquet. Duis imperdiet pulvinar rhoncus. Fusce tempor sem aliquet, mattis turpis vitae, rutrum orci. Aliquam in metus volutpat mi commodo dignissim et sed magna."

    dimmer (def & dimmerDimmed . event ?~ (Nothing <$ evt)) $ do
      divClass "ui text loader" $ text "Dimmed"
  |]

  mkExample "Content Dimmer" (def
    & subtitle ?~ text "A dimmer can have content")
    [example|
  evt <- buttons def $ do
    on <- button (def & buttonIcon |~ True) $ icon "plus" def
    off <- button (def & buttonIcon |~ True) $ icon "minus" def
    return $ leftmost [ Just In <$ on, Just Out <$ off ]

  segment def $ do
    header def $ text "Some Content"
    paragraph $ text $ "Suspendisse hendrerit justo id dignissim maximus. Ut maximus eu arcu sit amet egestas. Aenean et dictum felis. Ut rhoncus ipsum non luctus scelerisque. Proin pellentesque sed mauris efficitur aliquet. Duis imperdiet pulvinar rhoncus. Fusce tempor sem aliquet, mattis turpis vitae, rutrum orci. Aliquam in metus volutpat mi commodo dignissim et sed magna."
    paragraph $ text $ "Fusce varius bibendum eleifend. Integer ut finibus risus. Nunc non condimentum lorem. Sed aliquam scelerisque maximus. In hac habitasse platea dictumst. Nam mollis orci sem, vel posuere mi sollicitudin molestie. Praesent at pretium ex. Proin condimentum lacus sit amet risus volutpat, vitae feugiat ante iaculis. Nullam id interdum diam, nec sagittis quam. Ut finibus dapibus nunc sed tincidunt. Vestibulum mi lorem, euismod ut molestie id, viverra vitae ex."

    dimmer (def & dimmerDimmed . event ?~ evt) $ do
      divClass "content" $ divClass "center" $ do
        let conf = def & headerIcon ?~ Icon "heart" def
                       & headerLargeIcon |~ True
                       & headerInverted |~ True
        pageHeader H2 conf $ do
          text "Dimmed Message!"
  |]

  mkExample "Page Dimmer" (def
    & subtitle ?~ text "A dimmer can be fixed to the page")
    [example|
  on <- button def $ icon "plus" def >> text "Show"

  dimmer (def & dimmerPage .~ True
              & dimmerDimmed . event ?~ (Just In <$ on)) $ do
    divClass "content" $ divClass "center" $ do
      let conf = def & headerIcon ?~ Icon "mail" def
                     & headerLargeIcon |~ True
                     & headerInverted |~ True
      pageHeader H2 conf $ do
        text "Dimmed Message!"
        subHeader $ text "Dimmer sub-header"
  |]

  mkExample "Persitent Dimmer" (def
    & subtitle ?~ text "A dimmer can disable close on click")
    --[example|
      ("code", Left $ mdo
    on <- button def $ icon "plus" def >> text "Show"

    let conf = def
          & dimmerDimmed . event ?~ leftmost
            [ Just In <$ on, Just Out <$ close ]
          & dimmerPage .~ True
          & dimmerCloseOnClick |~ False

    close <- dimmer conf $ do
      divClass "content" $ divClass "center" $ do
        let conf = def & headerIcon ?~ Icon "warning sign" def
                       & headerLargeIcon |~ True
                       & headerInverted |~ True
        pageHeader H2 conf $ do
          text "Persistent Dimmer"
          subHeader $ text "You can't dismiss me without clicking the button"

        divider $ def & dividerHidden |~ True

        button def $ text "Dismiss"

    return ()
    )
--  |]

  mkExample "Dimmer Events" (def
    & subtitle ?~ text "A dimmer can respond to events")
    --[example|
      ("code", Left $ mdo

    let evt = leftmost
          [ Just In <$ domEvent Mouseenter e
          , Just Out <$ domEvent Mouseleave e ]
        imgConf = def & imageSize |?~ Medium

    (e, _) <- contentImage' "images/animals/cat.png" imgConf $ do
      dimmer (def & dimmerDimmed . event ?~ evt
                  & dimmerCloseOnClick |~ False) $ do
        divClass "content" $ divClass "center" $ do
          pageHeader H2 (def & headerInverted |~ True) $ text "Title"
          button (def & buttonEmphasis |?~ Primary) $ text "Add"
          button def $ text "View"

    return ()
    )
--  |]

  return ()

