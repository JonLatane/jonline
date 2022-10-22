# Jonline Web APIs

Jonline's web UI is rendered with Rocket templates https://rocket.rs/v0.5-rc/guide/responses/#templates.

Routes are setup so that this README and anything else outside of `web/assets` and `web/images` will not be served. Only `*.hbs` templates will be served up.

See `backend/src/web/native_web.rs` for more information on templating.
