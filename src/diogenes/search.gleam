//// Functions for searching an index.
////
//// Meilisearch supports keyword, vector, and hybrid search via GET and POST
//// endpoints. The POST variant is preferred for complex queries as it avoids
//// URL length limitations.
////
//// ## TODO
////
//// - [ ] Search with GET - `GET /indexes/{indexUid}/search`
//// - [ ] Search with POST - `POST /indexes/{indexUid}/search`
//// - [ ] Multi-search - `POST /multi-search`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Searches an index using query parameters in the URL.
///
/// Prefer `search_with_post` for complex queries to avoid URL length limits.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/search)
pub fn search_with_get(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = send_request
  todo
}

/// Searches an index using a JSON request body.
///
/// Supports all search parameters including filters, facets, vector search,
/// hybrid search, highlighting, cropping, and pagination.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/search)
pub fn search_with_post(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = send_request
  todo
}

/// Performs multiple independent search queries in a single HTTP request.
///
/// Each query in the list targets a specific index and can have its own
/// search parameters. Results are returned in the same order as the queries.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/multi_search)
pub fn multi_search(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}
