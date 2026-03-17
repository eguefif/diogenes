//// Functions for retrieving documents similar to a given document.
////
//// Meilisearch uses vector embedders to compute similarity between documents.
//// An embedder must be configured in the index settings before using these endpoints.
////
//// ## TODO
////
//// - [ ] Get similar documents with GET - `GET /indexes/{indexUid}/similar`
//// - [ ] Get similar documents with POST - `POST /indexes/{indexUid}/similar`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Retrieves documents similar to the given document using query parameters.
///
/// - index_uid: unique identifier of the target index
/// - document_id: primary key value of the reference document
/// - embedder: name of the embedder to use for similarity computation
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/similar)
pub fn similar_with_get(
  client: Client,
  index_uid: String,
  document_id: String,
  embedder: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = document_id
  let _ = embedder
  let _ = send_request
  todo
}

/// Retrieves documents similar to the given document using a JSON request body.
///
/// - index_uid: unique identifier of the target index
/// - document_id: primary key value of the reference document
/// - embedder: name of the embedder to use for similarity computation
///
/// Prefer this over `similar_with_get` when using complex filters.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/similar)
pub fn similar_with_post(
  client: Client,
  index_uid: String,
  document_id: String,
  embedder: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = document_id
  let _ = embedder
  let _ = send_request
  todo
}
