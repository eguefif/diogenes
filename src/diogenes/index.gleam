import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/index as sansio_index
import gleam/option.{type Option}
import internals/http_tooling.{send_request}

// TODO:
// - [x] get index
// - [ ] update index
// - [ ] swap index
// - [ ] list index fields

/// Creates a Meilisearch index
///
/// - uid: unique index identifier
/// - primary_key: id from the document to references as a primary_key
///
/// https://www.meilisearch.com/docs/reference/api/indexes/create-index
pub fn create_index(
  client: Client,
  uid: String,
  primary_key: Option(String),
) -> Result(MeilisearchResponse(a), Error) {
  let #(request, parser) = sansio_index.create_index(client, uid, primary_key)
  send_request(request, [401], parser)
}

/// Lists all Meilisearch indexes with pagination
///
/// - offset: number of indexes to skip (defaults to 0)
/// - limit: maximum number of indexes to return (defaults to 20)
///
/// https://www.meilisearch.com/docs/reference/api/indexes/list-all-indexes
pub fn list_index(
  client: Client,
  offset: Option(Int),
  limit: Option(Int),
) -> Result(MeilisearchResponse(sansio_index.Index), Error) {
  let #(request, parser) = sansio_index.list_index(client, offset, limit)
  send_request(request, [401], parser)
}

/// Deletes a Meilisearch index and all its documents, settings and tasks history
///
/// - uid: unique index identifier
///
/// https://www.meilisearch.com/docs/reference/api/indexes/delete-index
pub fn delete_index(
  client: Client,
  uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) = sansio_index.delete_index(client, uid)
  send_request(request, [401], parser)
}

/// Retrieves the metadata of a single index
///
/// - uid: unique index identifier
///
/// Returns the index uid, primary key, and creation/update timestamps.
/// Returns a 404 error if the index does not exist.
///
/// https://www.meilisearch.com/docs/reference/api/indexes/get-index
pub fn get_index(
  client: Client,
  uid: String,
) -> Result(MeilisearchResponse(sansio_index.Index), Error) {
  let #(request, parser) = sansio_index.get_index(client, uid)
  send_request(request, [401, 404], parser)
}
