import diogenes.{type Client, type Error, type MeilisearchResponse, Empty}
import gleam/http
import gleam/http/request.{type Request}
import internals/http_tooling.{create_base_request}

/// Check if the Meilisearch server is up and running
/// https://www.meilisearch.com/docs/reference/api/health/get-health
pub fn get_health(
  client: Client,
) -> #(Request(String), fn(Int, String) -> Result(MeilisearchResponse, Error)) {
  let req =
    create_base_request(client, "/health")
    |> request.set_body("")
    |> request.set_method(http.Get)
  #(req, fn(status: Int, _: String) {
    case status {
      200 -> Ok(Empty)
      _ -> panic
    }
  })
}
