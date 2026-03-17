//// Functions for managing Meilisearch experimental features.
////
//// Experimental features can be toggled at runtime without restarting the
//// server. They may change or be removed in future versions.
////
//// ## TODO
////
//// - [ ] Get experimental features - `GET /experimental-features`
//// - [ ] Configure experimental features - `PATCH /experimental-features`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

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
