//! A static, hand-maintained catalog of the models each `AIModelProvider.provider` variant
//! supports, and what each one can actually do (see `protos/ai_model_providers.proto`'s
//! `AIModelCapability`). None of Anthropic/OpenAI/Gemini expose a "list models" endpoint stable/
//! simple enough to build `AvailableAIModel`s from at request time, so this list is updated by hand
//! as new models ship -- see `models_for_provider`, used by `rpcs::ai_model_providers` to expand a
//! provider (or a grant's `model_names`) into the `AvailableAIModel`s a user can actually see.

use crate::protos::ai_model_provider::Provider;
use crate::protos::AiModelCapability;

/// One model in the catalog -- a name plus what it can actually do, per `AIModelCapability`'s own
/// doc. `name` is the exact string sent to the provider's own API (`AvailableAIModel.model_name`);
/// `capabilities` is what feature gating (e.g. `rpcs::ai_model_providers::generate_media`, which
/// requires `ImageEditing`) actually checks, rather than hardcoding model names of its own.
pub struct ModelInfo {
    pub name: &'static str,
    pub capabilities: &'static [AiModelCapability],
}

const IMAGE_EDITING_CAPABILITIES: &[AiModelCapability] =
    &[AiModelCapability::ImageGeneration, AiModelCapability::ImageEditing];
const IMAGE_GENERATION_ONLY_CAPABILITIES: &[AiModelCapability] = &[AiModelCapability::ImageGeneration];

/// Gemini API (`ai.google.dev/gemini-api`) image generation/editing models -- the "Nano Banana"
/// family, Jonline's actual near-term use case (generating/editing Event posters). Ordered
/// newest/most-capable first. `gemini-2.5-flash-image` is the original ("legacy") model; Google's
/// own docs now recommend `gemini-3.1-flash-lite-image` for new plain text-to-image work instead.
/// Only `gemini-3-pro-image` and `gemini-3.1-flash-image` support image *editing* (multi-turn,
/// passing a prior image back in as part of the prompt) -- see
/// `ai.google.dev/gemini-api/docs/image-generation#gemini-image-editing`.
pub const GEMINI_MODELS: &[ModelInfo] = &[
    ModelInfo { name: "gemini-3-pro-image", capabilities: IMAGE_EDITING_CAPABILITIES },
    ModelInfo { name: "gemini-3.1-flash-image", capabilities: IMAGE_EDITING_CAPABILITIES },
    ModelInfo { name: "gemini-3.1-flash-lite-image", capabilities: IMAGE_GENERATION_ONLY_CAPABILITIES },
    ModelInfo { name: "gemini-2.5-flash-image", capabilities: IMAGE_GENERATION_ONLY_CAPABILITIES },
];

/// OpenAI's GPT Image family (`platform.openai.com/docs/guides/image-generation`) -- generation via
/// `POST /v1/images/generations`, editing (given one or more reference images) via
/// `POST /v1/images/edits`, both `AiModelCapability::ImageGeneration`/`ImageEditing`-capable like
/// Gemini's own top-tier models. Ordered newest/most-capable first; `gpt-image-1-mini` trades
/// quality for speed/cost, otherwise all four support the same two endpoints.
pub const OPENAI_MODELS: &[ModelInfo] = &[
    ModelInfo { name: "gpt-image-2", capabilities: IMAGE_EDITING_CAPABILITIES },
    ModelInfo { name: "gpt-image-1.5", capabilities: IMAGE_EDITING_CAPABILITIES },
    ModelInfo { name: "gpt-image-1", capabilities: IMAGE_EDITING_CAPABILITIES },
    ModelInfo { name: "gpt-image-1-mini", capabilities: IMAGE_EDITING_CAPABILITIES },
];

/// Anthropic models -- empty for now, since `AnthropicCredentials` isn't yet accepted by
/// `CreateAIModelProvider` (see that message's own proto doc).
pub const ANTHROPIC_MODELS: &[ModelInfo] = &[];

/// Every model `provider`'s external service supports, regardless of any grant -- the full set an
/// owner sees. `None` (an unset `oneof`) has no models.
pub fn models_for_provider(provider: &Option<Provider>) -> &'static [ModelInfo] {
    match provider {
        Some(Provider::GeminiCredentials(_)) => GEMINI_MODELS,
        Some(Provider::OpenaiCredentials(_)) => OPENAI_MODELS,
        Some(Provider::AnthropicCredentials(_)) => ANTHROPIC_MODELS,
        None => &[],
    }
}

/// `capabilities` for one named model of `provider`'s catalog -- empty if `provider`/`model_name`
/// don't match anything known (e.g. a grant's `model_names` naming a model that's since been
/// dropped from the catalog). Used by `rpcs::ai_model_providers::generate_media` to check
/// `AiModelCapability::ImageEditing` without re-deriving a whole `AvailableAIModel` first.
pub fn capabilities_for_model(provider: &Option<Provider>, model_name: &str) -> &'static [AiModelCapability] {
    models_for_provider(provider)
        .iter()
        .find(|model| model.name == model_name)
        .map(|model| model.capabilities)
        .unwrap_or(&[])
}
