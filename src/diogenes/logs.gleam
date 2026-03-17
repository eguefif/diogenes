//// Functions for managing Meilisearch log streaming.
////
//// Meilisearch can stream structured logs over HTTP. Only one log stream
//// can be active at a time. The stream uses server-sent events and stays
//// open until cancelled.
////
//// ## TODO
////
//// - [ ] Retrieve logs - `POST /logs/stream`
//// - [ ] Stop retrieving logs - `DELETE /logs/stream`
//// - [ ] Update console log target - `POST /logs/stderr`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

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
