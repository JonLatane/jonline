-- SERVER CONFIGURATION MODEL
CREATE TABLE server_configurations (
  id BIGSERIAL PRIMARY KEY,
  active BOOLEAN NOT NULL DEFAULT TRUE,

  server_info JSONB NOT NULL DEFAULT '{}'::JSONB,

  anonymous_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  default_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  basic_user_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,

  people_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  group_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  post_settings JSONB NOT NULL DEFAULT '{}'::JSONB,
  event_settings JSONB NOT NULL DEFAULT '{}'::JSONB,

  external_cdn_config JSONB NULL DEFAULT NULL,

  private_user_strategy VARCHAR NOT NULL DEFAULT 'ACCOUNT_IS_FROZEN',
  authentication_features JSONB NOT NULL DEFAULT '[]'::JSONB,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- CORE USER/AUTH MODELS
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password_salted_hash VARCHAR NOT NULL,
  real_name VARCHAR NOT NULL DEFAULT '',
  email JSONB NULL DEFAULT NULL,
  phone JSONB NULL DEFAULT NULL,
  permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  avatar_media_id BIGINT NULL DEFAULT NULL,
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
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  device_name VARCHAR NOT NULL
);
CREATE UNIQUE INDEX idx_device_name ON user_devices(user_id, device_name);

CREATE TABLE user_refresh_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NULL DEFAULT NOW() + INTERVAL '1 day'
);

CREATE TABLE user_access_tokens (
  id BIGSERIAL PRIMARY KEY,
  refresh_token_id BIGINT NOT NULL REFERENCES user_refresh_tokens ON DELETE CASCADE,
  token VARCHAR NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '8 hour'
);
CREATE INDEX idx_access_tokens ON user_access_tokens(token);

CREATE TABLE follows (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  target_user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  target_user_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_follows ON follows(user_id, target_user_id);


-- MEDIA MODELS. Actual media data lives in MinIO/S3.
CREATE TABLE media (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NULL REFERENCES users ON DELETE SET NULL,
  minio_path VARCHAR NOT NULL,
  content_type VARCHAR NOT NULL,
  thumbnail_minio_path VARCHAR NULL DEFAULT NULL,
  thumbnail_content_type VARCHAR NULL DEFAULT NULL,
  name VARCHAR NULL DEFAULT NULL,
  description TEXT NULL DEFAULT NULL,
  generated BOOLEAN NOT NULL DEFAULT FALSE,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Users and Media have a cyclic dependency for the sake of the user avatar.
ALTER TABLE users ADD CONSTRAINT fk_user_avatar FOREIGN KEY (avatar_media_id) REFERENCES media(id);


-- GROUP MODELS
CREATE TABLE groups (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL UNIQUE,
  shortname VARCHAR NOT NULL UNIQUE,
  description TEXT NOT NULL DEFAULT '',
  avatar_media_id BIGINT NULL REFERENCES media ON DELETE SET NULL,
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  default_membership_permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  default_membership_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  default_post_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  default_event_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  member_count INTEGER NOT NULL DEFAULT 0,
  post_count INTEGER NOT NULL DEFAULT 0,
  event_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX group_shortname_lower ON groups (LOWER(shortname));

CREATE TABLE memberships (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  group_id BIGINT NOT NULL REFERENCES groups ON DELETE CASCADE,
  permissions JSONB NOT NULL DEFAULT '[]'::JSONB,
  group_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  user_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_membership ON memberships(user_id, group_id);


-- CORE SOCIAL/POST MODELS
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NULL REFERENCES users ON DELETE SET NULL,
  parent_post_id BIGINT NULL DEFAULT NULL REFERENCES posts ON DELETE SET NULL,

  -- In the APIs title is treated as optional. However, for ease of loading,
  -- the replying-to Post's title will always be duplicated in child posts/replies.
  title VARCHAR NULL DEFAULT NULL,
  link VARCHAR NULL DEFAULT NULL,
  content TEXT NULL DEFAULT NULL,

  response_count INTEGER NOT NULL DEFAULT 0,
  reply_count INTEGER NOT NULL DEFAULT 0,
  group_count INTEGER NOT NULL DEFAULT 0,

  media BIGINT[] NOT NULL DEFAULT '{}',
  media_generated BOOLEAN NOT NULL DEFAULT FALSE,
  embed_link BOOLEAN NOT NULL DEFAULT FALSE,
  shareable BOOLEAN NOT NULL DEFAULT FALSE,

  context VARCHAR NOT NULL DEFAULT 'POST',
  visibility VARCHAR NOT NULL DEFAULT 'SERVER_PUBLIC',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL,
  published_at TIMESTAMP NULL DEFAULT NULL,
  last_activity_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Speed up loading of posts by user.
CREATE INDEX idx_post_vis_parent_created ON posts(context, visibility, parent_post_id, created_at);
CREATE INDEX idx_post_vis_parent_activity ON posts(context, visibility, parent_post_id, last_activity_at);
CREATE INDEX idx_post_vis_user_created ON posts(context, visibility, user_id, created_at);
CREATE INDEX idx_post_vis_user_activity ON posts(context, visibility, user_id, last_activity_at);
CREATE INDEX idx_post_link_media ON posts(link, media_generated);
CREATE INDEX idx_post_vis ON posts(visibility);

CREATE TABLE group_posts(
  id BIGSERIAL PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES groups ON DELETE CASCADE,
  post_id BIGINT NOT NULL REFERENCES posts ON DELETE CASCADE,
  -- The user who shared the post to the group (not necessarily the author).
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  group_moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE UNIQUE INDEX idx_group_post ON group_posts(group_id, post_id);

CREATE TABLE user_posts(
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  post_id BIGINT NOT NULL REFERENCES posts ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE UNIQUE INDEX idx_user_post ON user_posts(user_id, post_id);

-- Event Models
CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES posts ON DELETE CASCADE,
  info JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
-- CREATE UNIQUE INDEX idx_event_post ON events(id, post_id);

CREATE TABLE event_instances (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events ON DELETE CASCADE,
  -- Event Instances can fallback to the event's post_id if there is none on the instance.
  post_id BIGINT NULL DEFAULT NULL REFERENCES posts ON DELETE SET NULL,
  info JSONB NOT NULL DEFAULT '{}'::JSONB,
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  location JSONB NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);
CREATE INDEX idx_event_instance_starts_at ON event_instances(starts_at);
CREATE INDEX idx_event_instance_ends_at ON event_instances(ends_at);

CREATE TABLE event_attendances (
  id BIGSERIAL PRIMARY KEY,
  event_instance_id BIGINT NOT NULL REFERENCES event_instances ON DELETE CASCADE,
  user_id BIGINT NULL REFERENCES users ON DELETE CASCADE,
  anonymous_attendee JSONB NULL DEFAULT NULL,
  number_of_guests INTEGER NOT NULL DEFAULT 0,
  -- INTERESTED, GOING, NOT_GOING, REQUESTED, WENT, DID_NOT_GO
  status VARCHAR NOT NULL DEFAULT 'INTERESTED',
  inviting_user_id BIGINT NULL DEFAULT NULL REFERENCES users ON DELETE SET NULL,
  public_note VARCHAR NOT NULL DEFAULT '',
  private_note VARCHAR NOT NULL DEFAULT '',
  moderation VARCHAR NOT NULL DEFAULT 'UNMODERATED',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NULL DEFAULT NULL
);

-- FEDERATION MODELS
CREATE TABLE federated_servers (
  id BIGSERIAL PRIMARY KEY,
  server_location VARCHAR NOT NULL
);
CREATE INDEX idx_server_locations ON federated_servers(server_location);

CREATE TABLE federated_accounts (
  id BIGSERIAL PRIMARY KEY,
  federated_server_id BIGINT NULL DEFAULT NULL REFERENCES federated_servers ON DELETE SET NULL,
  federated_user_id VARCHAR NOT NULL,
  -- Note that user_id may be null. In this case, the federated account doesn't belong to a
  -- user on this Jonline instance. There is a local user *following* the federated account.
  -- But the user being followed, who "lives" on the other server, has not (yet?) federated
  -- their account to this Jonline instance.
  user_id BIGINT NULL DEFAULT NULL REFERENCES users ON DELETE CASCADE
);
