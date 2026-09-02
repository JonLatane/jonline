//! A static, hand-maintained catalog of the models each `AIModelProvider.provider` variant
//! supports (see `protos/ai_model_providers.proto`). None of Anthropic/OpenAI/Gemini expose a
//! "list models" endpoint stable/simple enough to build `AvailableAIModel`s from at request time,
//! so this list is updated by hand as new models ship -- see `models_for_provider`, used by
//! `rpcs::ai_model_providers` to expand a provider (or a grant's `model_names`) into the
//! `AvailableAIModel`s a user can actually see.

use crate::protos::ai_model_provider::Provider;

/// Gemini API (`ai.google.dev/gemini-api`) image generation/editing models -- the "Nano Banana"
/// family, Jonline's actual near-term use case (generating/editing Event posters). Ordered
/// newest/most-capable first. `gemini-2.5-flash-image` is the original ("legacy") model; Google's
/// own docs now recommend `gemini-3.1-flash-lite-image` for new plain text-to-image work instead.
/// Only `gemini-3-pro-image` and `gemini-3.1-flash-image` support image *editing* (multi-turn,
/// passing a prior image back in as part of the prompt) -- see
/// `ai.google.dev/gemini-api/docs/image-generation#gemini-image-editing`.
pub const GEMINI_MODELS: &[&str] = &[
    "gemini-3-pro-image",
    "gemini-3.1-flash-image",
    "gemini-3.1-flash-lite-image",
    "gemini-2.5-flash-image",
];

/// OpenAI models -- empty for now, since `OpenAICredentials` isn't yet accepted by
/// `CreateAIModelProvider` (see that message's own proto doc).
pub const OPENAI_MODELS: &[&str] = &[];

/// Anthropic models -- empty for now, since `AnthropicCredentials` isn't yet accepted by
/// `CreateAIModelProvider` (see that message's own proto doc).
pub const ANTHROPIC_MODELS: &[&str] = &[];

/// Every model `provider`'s external service supports, regardless of any grant -- the full set an
/// owner sees. `None` (an unset `oneof`) has no models.
pub fn models_for_provider(provider: &Option<Provider>) -> &'static [&'static str] {
    match provider {
        Some(Provider::GeminiCredentials(_)) => GEMINI_MODELS,
        Some(Provider::OpenaiCredentials(_)) => OPENAI_MODELS,
        Some(Provider::AnthropicCredentials(_)) => ANTHROPIC_MODELS,
        None => &[],
    }
}
