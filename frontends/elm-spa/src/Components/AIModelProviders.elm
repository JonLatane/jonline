module Components.AIModelProviders exposing
    ( createAIModelProvider
    , deleteAIModelProvider
    , generateMedia
    , getAIModelProviders
    , grantAIModelProvider
    , hasImageEditingCapability
    , revokeAIModelProvider
    , updateAIModelProvider
    )

{-| RPC wrappers for `AIModelProvider`/`AIModelProviderGrant` (`protos/ai_model_providers.proto`)
-- mirrors `Components.EventSyncSources` in shape exactly: each takes the calling account/server as
an `AccountsPanel.MaybeAccountServer` and returns a `Task` resolving to
`( Maybe AccountsPanel.Msg, response )`, so a token refresh mid-request can still be forwarded on by
the caller (see `Shared.AccountsPanel.performWithAccountServer`).

`UserProfilePage` no longer fetches `AIModelProvider`s/`AvailableAIModel`s on its own initial load
(it reads `User.available_ai_models`, already carried by the resolved `User` -- see
`AIModelProvidersState`'s own doc), and every mutation now triggers a full `refetch` of that `User`.
`getAIModelProviders` is still used, though -- by that section's manual "Refresh" button
(`AIModelProvidersRefreshClicked`), which overlays just the fresh `providers`/`availableAiModels`
onto the resolved `User` without a whole-profile refetch.
-}

import Grpc
import Proto.Jonline
    exposing
        ( AIModelProvider
        , AIModelProviderGrant
        , AvailableAIModel
        , GenerateMediaRequest
        , GetAIModelProvidersResponse
        , GrantAIModelProviderRequest
        , Media
        , RevokeAIModelProviderRequest
        , defaultUser
        )
import Proto.Jonline.AIModelCapability exposing (AIModelCapability(..))
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)


{-| `targetUserId = ""` asks the backend for the caller's own providers (see
`backend/src/rpcs/ai_model_providers/get_ai_model_providers.rs`); any other id asks for that user's
providers instead, which only succeeds for an Admin caller.
-}
getAIModelProviders :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetAIModelProvidersResponse )
getAIModelProviders accountsPanelModel maybeAccountServer targetUserId =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getAIModelProviders { defaultUser | id = targetUserId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| Always creates a provider owned by the calling account -- the backend ignores/overrides any
`owner` sent (see `create_ai_model_provider.rs`), so there's no `targetUserId` parameter here
unlike `getAIModelProviders`.
-}
createAIModelProvider :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> AIModelProvider
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, AIModelProvider )
createAIModelProvider accountsPanelModel maybeAccountServer provider =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.createAIModelProvider provider
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


updateAIModelProvider :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> AIModelProvider
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, AIModelProvider )
updateAIModelProvider accountsPanelModel maybeAccountServer provider =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.updateAIModelProvider provider
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


deleteAIModelProvider :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> AIModelProvider
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteAIModelProvider accountsPanelModel maybeAccountServer provider =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteAIModelProvider { provider = Just provider }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )


{-| Grants (or resets) `granteeUserId`'s access to `providerId`, owned by the calling account.
Owner-only server-side -- see `RevokeAIModelProvider`'s own doc comment in
`ai_model_providers.proto` on why there's no Admin override.
-}
grantAIModelProvider :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> GrantAIModelProviderRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, AIModelProviderGrant )
grantAIModelProvider accountsPanelModel maybeAccountServer request =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.grantAIModelProvider request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


revokeAIModelProvider :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> RevokeAIModelProviderRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
revokeAIModelProvider accountsPanelModel maybeAccountServer request =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.revokeAIModelProvider request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )


{-| Generates (or edits, given reference `mediaIds`) an image via one of the calling account's
`AvailableAIModel`s -- see `GenerateMediaRequest`'s own doc (`ai_model_providers.proto`). Used by
`Shared.MediaGeneratorPanel`.
-}
generateMedia :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> GenerateMediaRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, Media )
generateMedia accountsPanelModel maybeAccountServer request =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.generateMedia request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| Whether `available` can actually do the image editing `generateMedia`/`Shared.MediaGeneratorPanel`
require -- `AvailableAIModel.capabilities` is the server's own hardcoded catalog for the model (see
`AIModelCapability`'s own doc, `ai_model_providers.proto`), not anything this frontend infers from
`modelName` itself. Used both to gate whether a Post/Event's "Generate Media…" button appears at all
(`Components.Posts.generateMediaButton`'s callers) and to filter the model chooser inside the panel
itself down to only the models that would actually work.
-}
hasImageEditingCapability : AvailableAIModel -> Bool
hasImageEditingCapability available =
    List.member AIMODELCAPABILITYIMAGEEDITING available.capabilities
