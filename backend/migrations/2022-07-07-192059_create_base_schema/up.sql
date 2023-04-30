-- SERVER CONFIGURATION MODEL
CREATE TABLE server_configurations (
  id SERIAL PRIMARY KEY,
  active BOOLEAN NOT NULL DEFAULT TRUE,

  server_info JSONB NOT NULL DEFAULT '{}'::JSONB,

  anonymous_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  default_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  basic_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,

  people_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  group_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  post_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  event_settings JSONB NOT NULL DEFAULT '{}'::JSONB,

  private_user_strategy VARCHAR NOT NULL DEFAULT 'ACCOUNT_IS_FROZEN',
  authentication_features JSONB NOT NULL DEFAULT '[]'::JSONB,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- CORE USER/AUTH MODELS
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password_salted_hash VARCHAR NOT NULL,
  email JSONB NULL DEFAULT NULL,
  phone JSONB NULL DEFAULT NULL,
  permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  avatar BYTEA NULL DEFAULT NULL,
  bio TEXT NOT NULL DEFAULT '',
  -- For user visibilities, PRIVATE is equivalent to a "frozen" account.
  -- LIMITED will be visible only to user the user is following.
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  default_follow_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  follower_count INTEGER NOT NULL DEFAULT 0,
  following_count INTEGER NOT NULL DEFAULT 0,
  group_count INTEGER NOT NULL DEFAULT 0,
  post_count INTEGER NOT NULL DEFAULT 0,
  event_count INTEGER NOT NULL DEFAULT 0,
  response_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- CREATE INDEX idx_users_username ON users(username);

--TODO: Harden Auth: use the user_devices table and add an FK to it to user_refresh_tokens.
--Then add refresh token rotation.
CREATE TABLE user_devices (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  device_name VARCHAR NOT NULL
);
CREATE UNIQUE INDEX idx_device_name ON user_devices(user_id, device_name);

CREATE TABLE user_refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NULL DEFAULT NOW() + INTERVAL '1 day'
);

CREATE TABLE user_access_tokens (
  id SERIAL PRIMARY KEY,
  refresh_token_id INTEGER NOT NULL REFERENCES user_refresh_tokens ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '1 hour'
);
CREATE INDEX idx_access_tokens ON user_access_tokens(token);

CREATE TABLE follows (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  target_user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  target_user_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE groups (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL UNIQUE,
  shortname VARCHAR NOT NULL UNIQUE,
  description TEXT NOT NULL DEFAULT '',
  avatar BYTEA NULL DEFAULT NULL,
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  default_membership_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  default_membership_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  default_post_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  default_event_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  member_count INTEGER NOT NULL DEFAULT 0,
  post_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX group_shortname_lower ON groups (LOWER(shortname));

CREATE TABLE memberships (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  group_id INTEGER NOT NULL REFERENCES groups ON DELETE CASCADE,
  permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  group_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  user_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_membership ON memberships(user_id, group_id);

-- MEDIA MODELS
CREATE TABLE media (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER NULL REFERENCES users ON DELETE CASCADE,
  minio_path VARCHAR NOT NULL,
  name VARCHAR NULL DEFAULT NULL,
  description TEXT NULL DEFAULT NULL, 
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- CORE SOCIAL/POST MODELS

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NULL REFERENCES users ON DELETE SET NULL,
  parent_post_id INTEGER NULL DEFAULT NULL REFERENCES posts ON DELETE SET NULL,
  -- In the APIs title is treated as optional. However, for ease of loading,
  -- the replying-to Post's title will always be duplicated in child posts/replies.
  title VARCHAR NULL DEFAULT NULL,
  link VARCHAR NULL DEFAULT NULL,
  content TEXT NULL DEFAULT NULL,
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  response_count INTEGER NOT NULL DEFAULT 0,
  reply_count INTEGER NOT NULL DEFAULT 0,
  group_count INTEGER NOT NULL DEFAULT 0,
  preview BYTEA NULL DEFAULT NULL,
  context VARCHAR NOT NULL DEFAULT 'POST',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL,
  last_activity_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Speed up loading of posts by user.
CREATE INDEX idx_post_vis_parent_created ON posts(context, visibility, parent_post_id, created_at);
CREATE INDEX idx_post_vis_parent_activity ON posts(context, visibility, parent_post_id, last_activity_at);
CREATE INDEX idx_post_vis_user_created ON posts(context, visibility, user_id, created_at);
CREATE INDEX idx_post_vis_user_activity ON posts(context, visibility, user_id, last_activity_at);
CREATE INDEX idx_post_vis ON posts(visibility);

CREATE TABLE group_posts(
  id SERIAL PRIMARY KEY,
  group_id INTEGER NOT NULL REFERENCES groups ON DELETE CASCADE,
  post_id INTEGER NOT NULL REFERENCES posts ON DELETE CASCADE,
  -- The user who shared the post to the group (not necessarily the author).
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  group_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE UNIQUE INDEX idx_group_post ON group_posts(group_id, post_id);

CREATE TABLE user_posts(
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
  post_id INTEGER NOT NULL REFERENCES posts ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE UNIQUE INDEX idx_user_post ON user_posts(user_id, post_id);

-- Event Models
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES posts ON DELETE CASCADE,
  info JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
-- CREATE UNIQUE INDEX idx_event_post ON events(id, post_id);

CREATE TABLE event_instances (
  id SERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES events ON DELETE CASCADE,
  -- Event Instances can fallback to the event's post_id if there is none on the instance.
  post_id INTEGER NULL DEFAULT NULL REFERENCES posts ON DELETE SET NULL,
  info JSONB NOT NULL DEFAULT '{}'::JSONB,
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE INDEX idx_event_instance_starts_at ON event_instances(starts_at);
CREATE INDEX idx_event_instance_ends_at ON event_instances(ends_at);

-- FEDERATION MODELS
CREATE TABLE federated_servers (
  id SERIAL PRIMARY KEY,
  server_location VARCHAR NOT NULL
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
