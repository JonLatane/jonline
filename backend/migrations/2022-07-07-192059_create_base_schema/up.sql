-- CORE USER/AUTH MODELS
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password_salted_hash VARCHAR NOT NULL,
  email VARCHAR NULL DEFAULT NULL,
  phone VARCHAR NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- CREATE INDEX idx_users_username ON users(username);

CREATE TABLE user_auth_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NULL DEFAULT NOW() + INTERVAL '1 day'
);

CREATE TABLE user_refresh_tokens (
  id SERIAL PRIMARY KEY,
  auth_token_id INTEGER NOT NULL REFERENCES user_auth_tokens ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '1 hour'
);
CREATE INDEX idx_refresh_tokens ON user_refresh_tokens(token);

-- FEDERATION MODELS
CREATE TABLE federated_servers (
  id SERIAL PRIMARY KEY,
  server_location VARCHAR NOT NULL,
  -- For ease of setup, Jonline instances by default use their own Certificate Authorities (CA).
  -- When this Jonline wants to talk to Bobline, it will need to get Bobline's CA cert
  ca_cert VARCHAR NULL DEFAULT NULL,
  tls_key VARCHAR NULL DEFAULT NULL
);
CREATE INDEX idx_server_locations ON federated_servers(server_location);

CREATE TABLE federated_accounts (
  id SERIAL PRIMARY KEY,
  federated_server_id INTEGER NULL DEFAULT NULL REFERENCES federated_servers ON DELETE SET NULL,
  federated_user_id VARCHAR NOT NULL,
  -- Note that user_id may be null. In this case, the federated account doesn't belong to a
  -- user on this Jonline instance. There is a local user *following* the federated account.
  -- But the user being followed, who "lives" on the other server, has not (yet?) federated
  -- their account to this Jonline instance.
  user_id INTEGER NULL DEFAULT NULL REFERENCES users ON DELETE CASCADE
);

-- CORE SOCIAL/POST MODELS
CREATE TABLE follows (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  -- Indicates the user at user_id is following a user on this Jonline instance.
  local_user_id INTEGER NULL REFERENCES users ON DELETE CASCADE,
  -- Indicates the user at user_id is following a user on another Jonline instance.
  federated_account_id INTEGER NULL REFERENCES users ON DELETE CASCADE
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NULL REFERENCES users ON DELETE SET NULL,
  parent_post_id INTEGER NULL DEFAULT NULL REFERENCES users ON DELETE SET NULL,
  -- In the APIs title is treated as optional. However, for ease of loading,
  -- the replying-to Post's title will always be duplicated in child posts/replies.
  title VARCHAR NOT NULL,
  link VARCHAR NULL DEFAULT NULL,
  content TEXT NULL DEFAULT NULL,
  published BOOLEAN NOT NULL DEFAULT 'f',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL,
  reply_count INTEGER NOT NULL DEFAULT 0
);
