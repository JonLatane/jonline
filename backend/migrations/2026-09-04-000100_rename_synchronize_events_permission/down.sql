UPDATE users
SET permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE memberships
SET permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE groups
SET non_member_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(non_member_permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE non_member_permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE groups
SET default_membership_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(default_membership_permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE default_membership_permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE server_configurations
SET anonymous_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(anonymous_user_permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE anonymous_user_permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE server_configurations
SET default_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(default_user_permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE default_user_permissions @> '["SYNC_EVENTS_FROM_ICS"]';

UPDATE server_configurations
SET basic_user_permissions = to_jsonb(array_replace(
  ARRAY(SELECT jsonb_array_elements_text(basic_user_permissions)),
  'SYNC_EVENTS_FROM_ICS', 'SYNCHRONIZE_EVENTS'
))
WHERE basic_user_permissions @> '["SYNC_EVENTS_FROM_ICS"]';
