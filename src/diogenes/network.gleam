//// Functions for managing Meilisearch network topology.
////
//// Network configuration allows connecting multiple Meilisearch instances
//// to enable federated search across remote nodes.
////
//// ## TODO
////
//// - [ ] Get network topology - `GET /network`
//// - [ ] Configure network - `PATCH /network`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

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
