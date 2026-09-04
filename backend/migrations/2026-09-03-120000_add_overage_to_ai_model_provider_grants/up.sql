-- How far a single `GenerateMedia` call's actual token usage overshot `tokens_remaining` the
-- moment it hit 0 (see `AIModelProviderGrant.overage`'s own proto doc) -- `tokens_remaining`
-- itself can't go negative (BIGINT, but always written clamped to >= 0), so this is where that
-- shortfall is recorded instead. Reset to 0 whenever `GrantAIModelProvider` resets
-- `tokens_remaining`.
ALTER TABLE ai_model_provider_grants ADD COLUMN overage BIGINT NOT NULL DEFAULT 0;
