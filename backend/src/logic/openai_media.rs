//! Calls OpenAI's Images API (`platform.openai.com/docs/guides/image-generation`) to generate a new
//! image (`POST /v1/images/generations`, no reference images) or edit existing ones (`POST
//! /v1/images/edits`, one or more reference images -- accepted as a multipart file array). Used by
//! `rpcs::ai_model_providers::generate_media`, mirroring `gemini_media`'s own shape (a
//! `content_type`/`bytes` result struct) but split across two endpoints rather than one, since
//! that's how OpenAI's own API is split. `OpenAi`-prefixed names avoid colliding with
//! `gemini_media`'s own `generate_image`/`GeneratedImage`, both re-exported flat into `crate::logic`.

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use serde_json::json;
use tonic::{Code, Status};

use crate::logic::http_client::blocking_json_request;

/// One existing image passed to OpenAI's edits endpoint alongside the prompt.
#[derive(Clone)]
pub struct OpenAiImageInput {
    pub content_type: String,
    pub bytes: Vec<u8>,
}

/// The image OpenAI generated, ready to store as a new `Media` row.
pub struct OpenAiGeneratedImage {
    pub content_type: String,
    pub bytes: Vec<u8>,
}

const OPENAI_GENERATIONS_URL: &str = "https://api.openai.com/v1/images/generations";
const OPENAI_EDITS_URL: &str = "https://api.openai.com/v1/images/edits";

/// Generates (no `reference_images`) or edits (one or more `reference_images`) an image via
/// `model_name` -- see the module doc for which endpoint each case hits.
pub fn openai_generate_image(
    api_key: &str,
    model_name: &str,
    prompt: &str,
    reference_images: &[OpenAiImageInput],
) -> Result<OpenAiGeneratedImage, Status> {
    if reference_images.is_empty() {
        generate(api_key, model_name, prompt)
    } else {
        edit(api_key, model_name, prompt, reference_images)
    }
}

fn generate(api_key: &str, model_name: &str, prompt: &str) -> Result<OpenAiGeneratedImage, Status> {
    let api_key = api_key.to_string();
    let body = json!({
        "model": model_name,
        "prompt": prompt,
        "size": "1024x1024",
    });

    let (status, value) = blocking_json_request(
        move |client| client.post(OPENAI_GENERATIONS_URL).bearer_auth(&api_key).json(&body),
        "openai_request_failed",
    )?;

    if !status.is_success() {
        log::error!("OpenAI image generation failed ({}): {:?}", status, value);
        return Err(Status::new(Code::FailedPrecondition, "openai_request_failed"));
    }
    parse_generated_image(&value)
}

fn edit(
    api_key: &str,
    model_name: &str,
    prompt: &str,
    reference_images: &[OpenAiImageInput],
) -> Result<OpenAiGeneratedImage, Status> {
    let api_key = api_key.to_string();
    let model_name = model_name.to_string();
    let prompt = prompt.to_string();
    let reference_images = reference_images.to_vec();

    let (status, value) = blocking_json_request(
        move |client| {
            let mut form = reqwest::blocking::multipart::Form::new()
                .text("model", model_name.clone())
                .text("prompt", prompt.clone());
            for (index, image) in reference_images.iter().enumerate() {
                let part = reqwest::blocking::multipart::Part::bytes(image.bytes.clone())
                    .file_name(format!("reference-{index}"))
                    .mime_str(&image.content_type)
                    .unwrap_or_else(|_| reqwest::blocking::multipart::Part::bytes(image.bytes.clone()));
                // OpenAI's edits endpoint takes its reference images as a repeated `image[]` field.
                form = form.part("image[]", part);
            }
            client.post(OPENAI_EDITS_URL).bearer_auth(&api_key).multipart(form)
        },
        "openai_request_failed",
    )?;

    if !status.is_success() {
        log::error!("OpenAI image edit failed ({}): {:?}", status, value);
        return Err(Status::new(Code::FailedPrecondition, "openai_request_failed"));
    }
    parse_generated_image(&value)
}

/// Both endpoints return the same shape: `{"data": [{"b64_json": "..."}]}`. OpenAI's Images API
/// always returns PNG unless a different `output_format` is explicitly requested (not done here),
/// so `content_type` is hardcoded rather than read back from the response.
fn parse_generated_image(value: &serde_json::Value) -> Result<OpenAiGeneratedImage, Status> {
    let data = value["data"][0]["b64_json"]
        .as_str()
        .ok_or_else(|| {
            log::error!("OpenAI response had no image output: {:?}", value);
            Status::new(Code::Internal, "openai_no_image_returned")
        })?;
    let bytes = STANDARD
        .decode(data)
        .map_err(|_| Status::new(Code::Internal, "openai_invalid_image_data"))?;
    Ok(OpenAiGeneratedImage { content_type: "image/png".to_string(), bytes })
}
