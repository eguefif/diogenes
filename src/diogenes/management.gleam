//// Functions for Meilisearch instance management.
////
//// ## TODO
////
//// - [ ] Stats - index stats, all indexes stats
//// - [x] Health - get health
//// - [ ] Version - get version
//// - [ ] Snapshots - create snapshot
//// - [ ] Dumps - create dump
//// - [ ] Logs - retrieve, stop, update target
//// - [ ] Metrics - get Prometheus metrics
//// - [ ] Experimental features - list, configure
//// - [ ] Network - get topology, configure, control

import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/management as sansio_management
import internal/http_tooling.{send_request}

/// Check if Meilisearch is up and running
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/health/get-health)
pub fn get_health(client: Client) -> Result(MeilisearchResponse(a), Error) {
  let #(request, parser) = sansio_management.get_health(client)
  send_request(request, [], parser)
}
