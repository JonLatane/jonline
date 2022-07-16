CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password_salted_hash VARCHAR NOT NULL,
  email VARCHAR NULL DEFAULT NULL,
  phone VARCHAR NULL DEFAULT NULL
);

CREATE INDEX idx_users_username ON users(username);

CREATE TABLE user_auth_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '1 day'
);

CREATE TABLE user_refresh_tokens (
  id SERIAL PRIMARY KEY,
  auth_token_id INTEGER NOT NULL REFERENCES user_auth_tokens ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '1 hour'
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NULL REFERENCES users ON DELETE SET NULL,
  parent_post_id INTEGER NULL DEFAULT NULL REFERENCES users ON DELETE SET NULL,
  title VARCHAR NOT NULL,
  body TEXT NOT NULL,
  published BOOLEAN NOT NULL DEFAULT 'f'
);

CREATE TABLE federated_servers (
  id SERIAL PRIMARY KEY,
  server_location VARCHAR NOT NULL,
  ca_cert VARCHAR NULL DEFAULT NULL
);

CREATE TABLE follows (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  -- Indicates the user at user_id is following a user on this Jonline instance.
  local_user_id INTEGER NULL REFERENCES users ON DELETE CASCADE,
  -- Together, these columns indicate a user following a federated user.
  federated_server_id INTEGER NULL DEFAULT NULL REFERENCES federated_servers ON DELETE SET NULL,
  federated_user_id VARCHAR NOT NULL
);
