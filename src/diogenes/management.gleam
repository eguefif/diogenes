//// Functions for Meilisearch instance management.
////
//// ## TODO
////
//// - [x] Stats - index stats, all indexes stats
//// - [x] Health - get health
//// - [ ] Version - get version
//// - [x] Snapshots - create snapshot
//// - [x] Dumps - create dump
//// - [x] Logs - retrieve, stop, update target
//// - [x] Metrics - get Prometheus metrics
//// - [x] Experimental features - list, configure
//// - [x] Network - get topology, configure, control
//// - [ ] Webhooks - list, create, get, update, delete
//// - [ ] Compact - compact index
//// - [ ] Export - export to remote Meilisearch

import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/management as sansio_management
import internal/http_tooling.{send_request}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

/// Retrieves statistics for a specific index.
///
/// Returns the number of documents, database size, whether the index is
/// currently being updated, and field distribution data.
///
/// - index_uid: unique identifier of the target index
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/stats)
pub fn get_index_stats(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = send_request
  todo
}

/// Retrieves statistics for all indexes.
///
/// Returns the total database size and per-index statistics.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/stats)
pub fn get_all_stats(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

/// Check if Meilisearch is up and running
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/health/get-health)
pub fn get_health(client: Client) -> Result(MeilisearchResponse(a), Error) {
  let #(request, parser) = sansio_management.get_health(client)
  send_request(request, [], parser)
}

// ---------------------------------------------------------------------------
// Version
// ---------------------------------------------------------------------------

/// Retrieves the version of Meilisearch.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/version)
pub fn get_version(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Snapshots
// ---------------------------------------------------------------------------

/// Triggers the creation of a database snapshot.
///
/// Snapshots are binary copies of the database and can be restored faster
/// than dumps, but are not portable across versions. This is an asynchronous
/// operation that returns a task.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/snapshot)
pub fn create_snapshot(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Dumps
// ---------------------------------------------------------------------------

/// Triggers the creation of a database dump.
///
/// The dump is saved to the path configured via `--dump-dir`. This is an
/// asynchronous operation that returns a task.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/dump)
pub fn create_dump(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Logs
// ---------------------------------------------------------------------------

/// Opens a log stream and begins sending log entries.
///
/// - target: log filter in the format `code_part=log_level`
///   (e.g. `"index_scheduler=info,meilisearch=debug"`)
/// - mode: log format, either `"human"` or `"json"` (default: `"human"`)
///
/// Returns 400 if a stream is already active.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/logs)
pub fn get_logs(
  client: Client,
  target: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = target
  let _ = send_request
  todo
}

/// Stops the currently active log stream.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/logs)
pub fn stop_logs(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Updates the log level written to stderr.
///
/// - target: log filter in the format `code_part=log_level`
///   (e.g. `"index_scheduler=info"`)
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/logs)
pub fn update_stderr_log_target(
  client: Client,
  target: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = target
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------

/// Retrieves Prometheus-compatible metrics for the Meilisearch instance.
///
/// Requires the `metrics` experimental feature to be enabled.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/stats)
pub fn get_metrics(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Experimental features
// ---------------------------------------------------------------------------

/// Retrieves the current state of all experimental features.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/experimental-features)
pub fn get_experimental_features(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Enables or disables experimental features.
///
/// Only the fields sent in the body are changed; omitted fields keep their
/// current value.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/experimental-features)
pub fn configure_experimental_features(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Network
// ---------------------------------------------------------------------------

/// Retrieves the current network topology configuration.
///
/// Returns the current node's identifier and the list of configured remote nodes.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/network)
pub fn get_network(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Updates the network topology configuration.
///
/// - self_node: optional identifier for this node
/// - remotes: optional map of remote node identifiers to their URL and search API key
///
/// Only the fields sent in the body are changed.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/network)
pub fn configure_network(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Sends a network control command.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/network)
pub fn network_control(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Webhooks
// ---------------------------------------------------------------------------

/// Lists all configured webhooks.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/webhooks)
pub fn list_webhooks(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Creates a new webhook.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/webhooks)
pub fn create_webhook(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Retrieves a single webhook by its uid.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/webhooks)
pub fn get_webhook(
  client: Client,
  webhook_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = webhook_uid
  let _ = send_request
  todo
}

/// Updates an existing webhook.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/webhooks)
pub fn update_webhook(
  client: Client,
  webhook_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = webhook_uid
  let _ = send_request
  todo
}

/// Deletes a webhook.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/webhooks)
pub fn delete_webhook(
  client: Client,
  webhook_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = webhook_uid
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Compact
// ---------------------------------------------------------------------------

/// Compacts an index, reclaiming unused disk space.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/compact)
pub fn compact_index(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = send_request
  todo
}

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

/// Exports data to a remote Meilisearch instance.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/export)
pub fn export_to_remote(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}
