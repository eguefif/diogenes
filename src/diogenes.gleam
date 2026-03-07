//// Gleam Meilisearch client
////

import diogenes/http_tooling.{create_base_req}
import diogenes/types.{type Client, Client}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option}
import gleam/uri

/// Return a client to be used anytime we build request
/// Expect an url such as http://127.0.0.1:7000
/// ```
///    let client = new_client("http://127.0.0.1:7000", None)
///    diogenes.health(client)
///```
pub fn new_client(url: String, api_key: Option(String)) -> Client {
  let assert Ok(uri) = uri.parse(url)
  Client(uri:, api_key:)
}

// TODO: Add a parser for the user to read the response

/// Check if the Meilisearch server is up and running
/// https://www.meilisearch.com/docs/reference/api/health/get-health
pub fn health(
  client: Client,
) -> #(Request(String), fn(Response(String)) -> Result(Nil, Nil)) {
  let req =
    create_base_req(client, "/health")
    |> request.set_body("")
  #(req, fn(response: Response(String)) {
    case response.status {
      _ if response.status < 200 -> Ok(Nil)
      _ if response.status < 300 -> Ok(Nil)
      _ -> Error(Nil)
    }
  })
}
