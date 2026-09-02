-- User-owned connections to external AI model APIs (see `protos/ai_model_providers.proto`'s
-- `AIModelProvider`). `configuration` stores the `oneof provider` the same way
-- `sync_destinations`/`event_sync_sources` do: `{"<snake_case_variant>": {...fields...}}`.
CREATE TABLE ai_model_providers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  name VARCHAR NOT NULL,
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP
);
CREATE INDEX idx_ai_model_providers_user_id ON ai_model_providers(user_id);

-- A grant of metered access to an `ai_model_providers` row (see `AIModelProviderGrant`). Upserted
-- on the unique (ai_model_provider_id, grantee_id) pair -- granting again resets tokens_remaining
-- rather than adding to it (see `GrantAIModelProvider`'s RPC doc).
CREATE TABLE ai_model_provider_grants (
  id BIGSERIAL PRIMARY KEY,
  ai_model_provider_id BIGINT NOT NULL REFERENCES ai_model_providers(id),
  grantee_id BIGINT NOT NULL REFERENCES users(id),
  -- The models this grant covers (see `AIModelProviderGrant.model_names`) -- empty means "any
  -- model this provider supports".
  model_names VARCHAR[] NOT NULL DEFAULT '{}',
  tokens_remaining BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP,
  UNIQUE (ai_model_provider_id, grantee_id)
);
CREATE INDEX idx_ai_model_provider_grants_provider_id ON ai_model_provider_grants(ai_model_provider_id);
CREATE INDEX idx_ai_model_provider_grants_grantee_id ON ai_model_provider_grants(grantee_id);
