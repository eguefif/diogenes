import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/health as sansio_health
import internal/http_tooling.{send_request}

/// Check if Meilisearch is up and running
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/health/get-health)
pub fn get_health(client: Client) -> Result(MeilisearchResponse(a), Error) {
  let #(request, parser) = sansio_health.get_health(client)
  send_request(request, [], parser)
}
