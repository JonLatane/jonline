-- Add the device_name column (varchar null) to the user_refresh_tokens table.
ALTER TABLE user_refresh_tokens ADD COLUMN device_name VARCHAR NULL DEFAULT NULL;
ALTER TABLE user_refresh_tokens ADD COLUMN third_party BOOLEAN NOT NULL DEFAULT FALSE;
