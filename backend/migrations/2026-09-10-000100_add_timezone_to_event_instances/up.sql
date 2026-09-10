-- An explicit IANA timezone (e.g. "America/New_York") for an EventInstance, set either by hand
-- (`CreateNewPanel`/`EventPage`'s new timezone selector) or from an ICS Sync Source's own
-- `DTSTART;TZID=...` -- preferred over `logic::resolve_timezone`'s Nominatim-geocoded guess
-- wherever both could apply (see `sync_event_instance`).
ALTER TABLE event_instances ADD COLUMN timezone VARCHAR;
