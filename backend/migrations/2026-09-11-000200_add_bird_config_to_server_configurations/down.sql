-- This file should undo anything in `up.sql`
ALTER TABLE server_configurations DROP COLUMN bird_config;
ALTER TABLE server_configurations DROP COLUMN preferred_verification_apis;
