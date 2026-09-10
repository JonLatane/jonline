-- Backs `ServerConfiguration.cluster_resources` (see that field's own doc in
-- server_configuration.proto). Nullable/JSONB like `external_cdn_config`/`web_push_config`, with
-- one deliberate difference: `LockClusterResources`/`FreeClusterResources` update this column in
-- place on the active row rather than going through `ConfigureServer`'s usual
-- deactivate-old/insert-new versioning -- see `ClusterResources.conductor_state`'s own doc.
ALTER TABLE server_configurations ADD COLUMN cluster_resources JSONB;
