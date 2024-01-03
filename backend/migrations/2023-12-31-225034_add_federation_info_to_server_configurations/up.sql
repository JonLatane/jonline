-- Your SQL goes here
ALTER TABLE server_configurations ADD COLUMN federation_info JSONB NOT NULL DEFAULT '{"servers": []}'::JSONB;
