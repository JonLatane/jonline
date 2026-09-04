-- The `SYNCHRONIZE_EVENTS` permission (enum value 36) was replaced by `SYNC_EVENTS_FROM_ICS`
-- (enum value 700) -- see protos/permissions.proto. Permissions are stored as JSONB arrays of
-- the enum's string name (see backend/src/marshaling/permission_marshaling.rs), so the enum's
-- numeric renumbering doesn't matter here -- only the stored string needs updating.
UPDATE users
SET permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE memberships
SET permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE groups
SET non_member_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(non_member_permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE non_member_permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE groups
SET default_membership_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(default_membership_permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE default_membership_permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE server_configurations
SET anonymous_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(anonymous_user_permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE anonymous_user_permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE server_configurations
SET default_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(default_user_permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE default_user_permissions @> '["SYNCHRONIZE_EVENTS"]';

UPDATE server_configurations
SET basic_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(basic_user_permissions)),
  'SYNCHRONIZE_EVENTS', 'SYNC_EVENTS_FROM_ICS'
))
WHERE basic_user_permissions @> '["SYNCHRONIZE_EVENTS"]';
