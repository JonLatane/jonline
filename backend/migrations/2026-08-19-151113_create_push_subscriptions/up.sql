-- Web Push subscriptions registered by users (see `protos/messages.proto`'s `PushSubscription`).
-- One row per (user, browser subscription): a user with several browsers/devices registers
-- several rows, and the same physical device can carry a row for each account it's signed into.
CREATE TABLE push_subscriptions(
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  endpoint VARCHAR NOT NULL,
  p256dh_key VARCHAR NOT NULL,
  auth_key VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Re-registering an endpoint already on file for this user (e.g. `PushManager.subscribe()`
  -- refreshing its keys) updates this row in place -- see `RegisterPushSubscription`'s RPC doc.
  UNIQUE (user_id, endpoint)
);
