//// Provides internals http tooling functions
////

import diogenes/types.{type Client}
import gleam/http
import gleam/http/request.{type Request}
import gleam/option.{type Option, None, Some}

pub fn create_base_req(client: Client, path: String) -> Request(String) {
  let assert Ok(req) = request.from_uri(client.uri)
  req
  |> request.set_path(path)
  |> request.set_method(http.Get)
  |> set_auth(client.api_key)
}

fn set_auth(req: Request(String), api_key: Option(String)) -> Request(String) {
  case api_key {
    Some(key) -> req |> request.set_header("Authorization", "Beader " <> key)
    None -> req
  }
}
