//// Functions for retrieving Meilisearch statistics.
////
//// Stats provide information about document counts, database size, field
//// distributions, and whether an index is currently being updated.
////
//// ## TODO
////
//// - [ ] Get stats of index - `GET /indexes/{indexUid}/stats`
//// - [ ] Get stats of all indexes - `GET /stats`
//// - [ ] Get prometheus metrics - `GET /metrics`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

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
