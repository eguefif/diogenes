//// Functions for facet searching an index.
////
//// Facet search returns matching facet values for a given facet attribute,
//// optionally filtered by a query string and document filters.
////
//// ## TODO
////
//// - [ ] Perform a facet search - `POST /indexes/{indexUid}/facet-search`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Searches for facet values matching a query within a specific facet attribute.
///
/// - index_uid: unique identifier of the target index
/// - facet_name: the facet attribute to search (must be in filterableAttributes)
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/facet_search)
pub fn facet_search(
  client: Client,
  index_uid: String,
  facet_name: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = index_uid
  let _ = facet_name
  let _ = send_request
  todo
}
