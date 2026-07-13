module Effect exposing
    ( Effect, none, map, batch
    , fromCmd, fromShared
    , toCmd, partitionShared
    )

{-|

@docs Effect, none, map, batch
@docs fromCmd, fromShared
@docs toCmd, partitionShared

-}

import Shared
import Task


type Effect msg
    = None
    | Cmd (Cmd msg)
    | Shared Shared.Msg
    | Batch (List (Effect msg))


none : Effect msg
none =
    None


map : (a -> b) -> Effect a -> Effect b
map fn effect =
    case effect of
        None ->
            None

        Cmd cmd ->
            Cmd (Cmd.map fn cmd)

        Shared msg ->
            Shared msg

        Batch list ->
            Batch (List.map (map fn) list)


fromCmd : Cmd msg -> Effect msg
fromCmd =
    Cmd


fromShared : Shared.Msg -> Effect msg
fromShared =
    Shared


batch : List (Effect msg) -> Effect msg
batch =
    Batch



-- Used by Main.elm


toCmd : ( Shared.Msg -> msg, pageMsg -> msg ) -> Effect pageMsg -> Cmd msg
toCmd ( fromSharedMsg, fromPageMsg ) effect =
    case effect of
        None ->
            Cmd.none

        Cmd cmd ->
            Cmd.map fromPageMsg cmd

        Shared msg ->
            Task.succeed msg
                |> Task.perform fromSharedMsg

        Batch list ->
            Cmd.batch (List.map (toCmd ( fromSharedMsg, fromPageMsg )) list)


{-| Pulls every `Shared.Msg` out of an effect tree (in order), leaving behind
whatever's left (plain `Cmd`s) to still go through `toCmd` as usual.

Exists so `Main.elm` can fold page-forwarded `Shared.Msg`s into `Shared.update`
directly, in the same `update` call that produced them, rather than via
`toCmd`'s `Task.perform` -- which defers them to a later `update`/`view` cycle.
That one extra cycle is invisible for most effects, but for something typed
into every keystroke (the Accounts Panel's login form, which lives in
`Shared.Model` since it's shown from every page's header) it means `view` runs
once with the stale pre-keystroke model -- snapping a mid-edit cursor to the
end of the old text -- and then again with the correct one, snapping it again.
Applying the `Shared.Msg` synchronously avoids that extra render entirely.
-}
partitionShared : Effect msg -> ( List Shared.Msg, Effect msg )
partitionShared effect =
    case effect of
        None ->
            ( [], None )

        Cmd _ ->
            ( [], effect )

        Shared msg ->
            ( [ msg ], None )

        Batch list ->
            let
                ( sharedMsgLists, effects ) =
                    List.map partitionShared list
                        |> List.unzip
            in
            ( List.concat sharedMsgLists, Batch effects )
