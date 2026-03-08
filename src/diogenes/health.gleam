import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/health as sansio_health
import internals/http_tooling.{send_request}

pub fn get_health(client: Client) -> Result(MeilisearchResponse, Error) {
  let #(request, parser) = sansio_health.get_health(client)
  send_request(request, [], parser)
}
