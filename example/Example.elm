module Example exposing (main)

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
    BeautifulExample.element
        { title = "Fluent-Web"
        , details =
            Just """A demonstration of using fluent-web custom web components for 3 locales, en-US, pl and cs. These components are for doing l10n using https://projectfluent.org/"""
        , color = Just Color.blue
        , maxWidth = 400
        , githubUrl = Just "https://github.com/wolfadex/fluent-web"
        , documentationUrl = Nothing
        }
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { messages : List ( Locale, Localization )
    , activeLocale : Locale
    , personName : String
    , time : Posix
    , zone : Zone
    , placeholderInput : String
    }


type Msg
    = ChangeLocale String
    | SetPersonName String
    | SetZone Zone
    | SetTime Posix
    | SetPlaceholderInput String
    | ClearPlaceholder


type alias Localization =
    String


type Locale
    = EnUS
    | Pl
    | Cs


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


localeFromString : String -> Result String Locale
localeFromString localeStr =
    case localeStr of
        "en-US" ->
            Ok EnUS

        "pl" ->
            Ok Pl

        "cs" ->
            Ok Cs

        _ ->
            Err ("unsupported localce: " ++ localeStr)


type alias Flags =
    List ( String, Localization )


init : Flags -> ( Model, Cmd Msg )
init messages =
    ( { messages =
            List.foldl
                (\( localeStr, localization ) res ->
                    case localeFromString localeStr of
                        Ok locale ->
                            ( locale, localization ) :: res

                        Err _ ->
                            res
                )
                []
                messages
      , activeLocale = EnUS
      , personName = "Carl"
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , placeholderInput = ""
      }
    , Cmd.batch
        [ Task.perform SetTime Time.now
        , Task.perform SetZone Time.here
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeLocale newLocale ->
            case localeFromString newLocale of
                Ok locale ->
                    ( { model | activeLocale = locale }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        SetPersonName name ->
            ( { model | personName = name }, Cmd.none )

        SetZone zone ->
            ( { model | zone = zone }, Cmd.none )

        SetTime time ->
            ( { model | time = time }, Cmd.none )

        SetPlaceholderInput val ->
            ( { model | placeholderInput = val }, Cmd.none )

        ClearPlaceholder ->
            ( { model | placeholderInput = "" }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        messages =
            model.messages
                |> List.filter (\( locale, _ ) -> model.activeLocale == locale)
                |> List.head
    in
    Html.div
        []
        [ Html.label
            []
            [ Html.text "Active Locale"
            , Html.select
                [ Html.Events.onInput ChangeLocale ]
                [ Html.option
                    [ Html.Attributes.value (localeToString EnUS) ]
                    [ Html.text "en-US" ]
                , Html.option
                    [ Html.Attributes.value (localeToString Pl) ]
                    [ Html.text "pl" ]
                , Html.option
                    [ Html.Attributes.value (localeToString Cs) ]
                    [ Html.text "cs" ]
                ]
            ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "Basic key-value:"
        , Html.br [] []
        , Html.node "fluent-web"
            [ Html.Attributes.property "messages" <|
                case messages of
                    Just m ->
                        Json.Encode.list encodeMessages [ m ]

                    Nothing ->
                        Json.Encode.null
            , Html.Attributes.attribute "messageId" "hello-no-name"
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Styled key-value:"
        , Html.br [] []
        , Html.node "fluent-web"
            [ Html.Attributes.property "messages" <|
                case messages of
                    Just m ->
                        Json.Encode.list encodeMessages [ m ]

                    Nothing ->
                        Json.Encode.null
            , Html.Attributes.attribute "messageId" "sign-in-or-cancel"
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Today's Date:"
        , Html.br [] []
        , Html.node "fluent-web"
            [ Html.Attributes.property "messages" <|
                case messages of
                    Just m ->
                        Json.Encode.list encodeMessages [ m ]

                    Nothing ->
                        Json.Encode.null
            , Html.Attributes.attribute "messageId" "today-date"
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
        , Html.node "fluent-web"
            [ Html.Attributes.property "messages" <|
                case messages of
                    Just m ->
                        Json.Encode.list encodeMessages [ m ]

                    Nothing ->
                        Json.Encode.null
            , Html.Attributes.attribute "messageId" "hello"
            , Html.Attributes.property "args" <|
                Json.Encode.object
                    [ ( "userName", Json.Encode.string model.personName ) ]
            ]
            []
        , Html.br [] []
        , Html.br [] []
        , Html.text "Input localized:"
        , Html.br [] []
        , Html.node "fluent-web"
            [ Html.Attributes.property "messages" <|
                case messages of
                    Just m ->
                        Json.Encode.list encodeMessages [ m ]

                    Nothing ->
                        Json.Encode.null
            , Html.Attributes.attribute "messageId" "type-name"
            , Html.Attributes.attribute "messageTag" "input"
            , Html.Events.onInput SetPlaceholderInput
            , Html.Attributes.attribute "carl" "steve"
            , Html.Attributes.value model.placeholderInput
            , Html.Events.onClick ClearPlaceholder
            ]
            []
        ]


encodeMessages : ( Locale, Localization ) -> Value
encodeMessages ( locale, messages ) =
    Json.Encode.list identity
        [ Json.Encode.string (localeToString locale), Json.Encode.string messages ]
