{-# language NamedFieldPuns    #-}
{-# language OverloadedStrings #-}
{-# language RecordWildCards   #-}

module Main where

import           Hinc.Parser
import           Language.Haskell.Exts.Pretty (Pretty, prettyPrint)
import           Miso
import           Miso.String                  (JSString, fromMisoString, toMisoString)
import           Text.Megaparsec

main :: IO ()
main = startApp App {..}
  where
    initialAction = Translate
    model  = Model (toMisoString initialCode) ""
    update = updateModel
    view   = viewModel
    events = defaultEvents
    subs   = []
    mountPoint = Nothing
    logLevel = Off

initialCode = unlines [
    "let f(xs: List<Int>, p: (Int) => Bool): List<a>"
  , "  = effect {"
  , "      let x = await xs"
  , "      guard(p(x))"
  , "      x.add(1).pure"
  , "    }"
  ]

data Model = Model {
  currentText :: JSString
, translated  :: JSString
} deriving (Show, Eq)

data Action
  = ChangeCurrentText JSString
  | Translate
  deriving (Show, Eq)

updateModel :: Action -> Model -> Effect Action Model
updateModel (ChangeCurrentText t) m
  = noEff (m { currentText = t })
updateModel Translate m
  = let s = fromMisoString $ currentText m
    in case map prettyPrint <$> Text.Megaparsec.parse letBindP "test" s of
      Left  e -> noEff (m { translated = toMisoString (show e) })
      Right s -> noEff (m { translated = toMisoString (unlines s) })


-- | Constructs a virtual DOM from a model
viewModel :: Model -> View Action
viewModel Model { currentText, translated }
  = div_ [ class_ "jumbotron vh-100"] [
      h1_ [ class_ "display-4" ] [ text "Haskell In New Clothes" ]
    , p_ [ class_ "lead" ]
         [ text "Braces-and-parens syntax for your favorite language "
         , a_ [ href_ "https://github.com/serras/hinc/blob/master/why.md" ] [ text "Why?" ] ]
    , div_ [ class_ "row" ] [
        div_ [ class_ "col" ] [
          textarea_ [ class_ "form-control text-monospace"
                    , onChange ChangeCurrentText
                    , rows_ "10" ]
                    [ text currentText ]
        ]
      , div_ [ class_ "col-1" ] [
          button_ [ class_ "btn btn-primary"
                  , onClick Translate ]
                  [ text "->" ]
        ]
      , div_ [ class_ "col" ] [
          textarea_ [ class_ "form-control text-monospace"
                    , rows_ "10"
                    , readonly_ True ]
                    [ text translated ]
        ]
      ]
    , div_ [ class_ "text-muted" ]
           [ text "Proudly \129322 developed by "
           , a_ [ href_ "https://twitter.com/trupill" ] [ text "@trupill" ]
           , text " using "
           , a_ [ href_ "https://haskell-miso.org/" ] [ text "Miso 🍲" ]
           ]
    , link_ [ rel_ "stylesheet"
            , href_ "https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" ]
    ]
