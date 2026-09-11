-- Your SQL goes here
ALTER TABLE server_configurations
ADD COLUMN bird_config JSONB;
ALTER TABLE server_configurations
ADD COLUMN preferred_verification_apis JSONB;
