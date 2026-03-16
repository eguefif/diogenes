import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/settings as sansio_settings
import internal/http_tooling.{send_request}

pub fn list_all_settings(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(sansio_settings.Settings), Error) {
  let #(request, parser) = sansio_settings.list_all_settings(client, index_uid)
  send_request(request, [401, 404], parser)
}
