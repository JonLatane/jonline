CREATE TABLE federated_users(
  id BIGSERIAL PRIMARY KEY,
  remote_user_id VARCHAR NOT NULL,
  server_host VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_federated_user_id_server_host 
ON federated_users(remote_user_id, server_host);

CREATE TABLE federated_profiles(
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  federated_user_id BIGINT NOT NULL REFERENCES federated_users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_federated_profile_user_id_federated_user_id
ON federated_profiles(user_id, federated_user_id);
