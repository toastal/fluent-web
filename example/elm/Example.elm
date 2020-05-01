port module Example exposing (main)

import BeautifulExample
import Color
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Task
import Time exposing (Posix, Zone)


main : Program Flags Model Msg
main =
    let
        oxfordCommaify : (a -> String) -> List a -> String
        oxfordCommaify stringifier list =
            case List.reverse (List.map stringifier list) of
                [] ->
                    ""

                x :: [] ->
                    x

                y :: x :: [] ->
                    x ++ " and " ++ y

                z :: zs ->
                    String.join ", " (List.reverse (("and " ++ z) :: zs))
    in
    BeautifulExample.element
        { title = "Fluent-Web"
        , details =
            Just
                (String.join " "
                    [ "A demonstration of using fluent-web custom web components for"
                    , String.fromInt (List.length allLocales)
                    , "locales,"
                    , oxfordCommaify localeToString allLocales ++ "."
                    , "These components are for doing l10n using https://projectfluent.org/."
                    ]
                )
        , color = Just Color.blue
        , maxWidth = 400
        , githubUrl = Just "https://github.com/wolfadex/fluent-web"
        , documentationUrl = Just "https://github.com/wolfadex/fluent-web/blob/master/docs/index.md"
        }
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { bundles : Bundles
    , activeLocale : Locale
    , personName : String
    , time : Posix
    , zone : Zone
    , placeholderInput : String
    , favoriteFruit : Fruit
    }


type Msg
    = ChangeLocale String
    | SetPersonName String
    | SetZone Zone
    | SetTime Posix
    | SetPlaceholderInput String
    | SetFavoriteFruit String
    | GotBundles Bundles


type alias Bundles =
    Value


type Fruit
    = Apple
    | Orange
    | Lemon


fruitToString : Fruit -> String
fruitToString fruit =
    case fruit of
        Apple ->
            "apple"

        Orange ->
            "orange"

        Lemon ->
            "lemon"


fruitFromString : String -> Result String Fruit
fruitFromString maybeFruit =
    case maybeFruit of
        "apple" ->
            Ok Apple

        "orange" ->
            Ok Orange

        "lemon" ->
            Ok Lemon

        _ ->
            Err ("Unknown fruit: " ++ maybeFruit)


allFruit : List Fruit
allFruit =
    [ Apple, Orange, Lemon ]


type Locale
    = EnUS
    | Pl
    | Cs
    | ThTH
    | Eo


allLocales : List Locale
allLocales =
    [ EnUS
    , Pl
    , Cs
    , ThTH
    , Eo
    ]


decodeLocale : Decoder Locale
decodeLocale =
    Json.Decode.string
        |> Json.Decode.andThen
            (\localeStr ->
                case localeFromString localeStr of
                    Ok locale ->
                        Json.Decode.succeed locale

                    Err err ->
                        Json.Decode.fail err
            )


localeToString : Locale -> String
localeToString locale =
    case locale of
        EnUS ->
            "en-US"

        Pl ->
            "pl"

        Cs ->
            "cs"

        ThTH ->
            "th-TH"

        Eo ->
            "eo"


localeFromString : String -> Result String Locale
localeFromString localeStr =
    case localeStr of
        "en-US" ->
            Ok EnUS

        "pl" ->
            Ok Pl

        "cs" ->
            Ok Cs

        "th-TH" ->
            Ok ThTH

        "eo" ->
            Ok Eo

        _ ->
            Err ("unsupported locale: " ++ localeStr)


type alias Flags =
    { bundles : Bundles
    , initialLocale : String
    }


init : Flags -> ( Model, Cmd Msg )
init { bundles, initialLocale } =
    ( { bundles = bundles
      , activeLocale =
            localeFromString initialLocale
                |> Result.toMaybe
                |> Maybe.withDefault EnUS
      , personName = "Carl"
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , placeholderInput = ""
      , favoriteFruit = Apple
      }
    , Cmd.batch
        [ Task.perform SetTime Time.now
        , Task.perform SetZone Time.here
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotBundles GotBundles


port gotBundles : (Bundles -> msg) -> Sub msg


port changeDesirecLocale : List String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotBundles bundles ->
            ( { model | bundles = bundles }, Cmd.none )

        ChangeLocale newLocale ->
            ( model, changeDesirecLocale [newLocale] )

        SetPersonName name ->
            ( { model | personName = name }, Cmd.none )

        SetZone zone ->
            ( { model | zone = zone }, Cmd.none )

        SetTime time ->
            ( { model | time = time }, Cmd.none )

        SetPlaceholderInput val ->
            ( { model | placeholderInput = val }, Cmd.none )

        SetFavoriteFruit fruitStr ->
            case fruitFromString fruitStr of
                Ok fruit ->
                    ( { model | favoriteFruit = fruit }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        bundless =
            model.bundles
                |> Html.Attributes.property "bundles"
    in
    Html.div
        []
        [ Html.label
            []
            [ Html.text "Active Locale"
            , Html.select
                [ Html.Events.onInput ChangeLocale ]
                (List.map
                    (\locale ->
                        Html.option
                            [ Html.Attributes.value (localeToString locale) ]
                            [ Html.text (localeToString locale) ]
                    )
                    allLocales
                )
            ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "Basic key-value:"
        , Html.br [] []
        , Html.node "fluent-text"
            [ bundless
            , Html.Attributes.attribute "messageid" "hello-no-name"
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Styled key-value:"
        , Html.br [] []
        , Html.node "fluent-text"
            [ bundless
            , Html.Attributes.attribute "messageid" "sign-in-or-cancel"
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Today’s Date:"
        , Html.br [] []
        , Html.node "fluent-text"
            [ bundless
            , Html.Attributes.attribute "messageid" "today-date"
            , Html.Attributes.property "args" <|
                Json.Encode.object
                    [ ( "date", Json.Encode.int (Time.posixToMillis model.time) ) ]
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Message with argument:"
        , Html.br [] []
        , Html.input
            [ Html.Attributes.value model.personName
            , Html.Events.onInput SetPersonName
            ]
            []
        , Html.br [] []
        , Html.node "fluent-text"
            [ bundless
            , Html.Attributes.attribute "messageid" "hello"
            , Html.Attributes.property "args" <|
                Json.Encode.object
                    [ ( "userName", Json.Encode.string model.personName ) ]
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Input localized:"
        , Html.br [] []
        , Html.node "fluent-element"
            [ bundless
            , Html.Attributes.attribute "messageid" "type-name"
            , Html.Attributes.property "attributeWhitelist" <|
                Json.Encode.list Json.Encode.string ["placeholder"]
            ]
            [ Html.input
                [ Html.Events.onInput SetPlaceholderInput
                , Html.Attributes.value model.placeholderInput
                ]
                []
            ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "Select with localized options:"
        , Html.br [] []
        , Html.label
            []
            [ Html.node "fluent-text"
                [ bundless
                , Html.Attributes.attribute "messageid" "favorite-fruit"
                ]
                []
            ]
        , Html.select
            [ Html.Events.onInput SetFavoriteFruit
            , Html.Attributes.value (fruitToString model.favoriteFruit)
            ]
            (List.map
                (\fruit ->
                    Html.option
                        [ Html.Attributes.value (fruitToString fruit)
                        ]
                        [ Html.node "fluent-text"
                            [ bundless
                            , Html.Attributes.attribute "messageid" ("fruit-" ++ fruitToString fruit)
                            ]
                            []
                        ]
                )
                allFruit
            )
        , Html.br [] []
        , Html.br [] []
        , Html.text "Provider-based messages:"
        , Html.br [] []
        , Html.node "fluent-provider"
            [ bundless ]
            [ Html.node "fluent-text"
                [ Html.Attributes.attribute "messageid" "hello-no-name"
                ]
                []
            , Html.br [] []
            , Html.node "fluent-text"
                [ Html.Attributes.attribute "messageid" "sign-in-or-cancel"
                ]
                []
            ]
        ]
