-- Data-only migration. This migration fixes events whose instance visibilities are mismatched.
update posts ip
set visibility = p.visibility
from events e, event_instances i, posts p
where e.post_id = p.id
  and i.event_id = e.id
  and i.post_id = ip.id
  and p.visibility != ip.visibility;
