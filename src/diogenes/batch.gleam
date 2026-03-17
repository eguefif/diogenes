//// Functions for retrieving Meilisearch batches.
////
//// A batch groups one or more tasks that were processed together. Batches
//// are read-only and are created automatically by Meilisearch.
////
//// ## TODO
////
//// - [ ] Get batches - `GET /batches`
//// - [ ] Get one batch - `GET /batches/{batchUid}`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Retrieves a paginated list of all batches, with optional filters.
///
/// Batches are returned in descending order of uid (most recent first).
/// Supports the same filters as the tasks endpoint.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/batches)
pub fn get_batches(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Retrieves a single batch by its uid.
///
/// - batch_uid: unique identifier of the batch
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/batches)
pub fn get_batch(
  client: Client,
  batch_uid: Int,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = batch_uid
  let _ = send_request
  todo
}
