//// Provides internal http tooling functions
////

import diogenes.{
  type Client, type Error, type MeilisearchResponse, TransportError,
  UnexpectedHttpStatusCodeError,
}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}

// This function create the base request uses for every Meilisearch request.
pub fn create_base_request(client: Client, path: String) -> Request(String) {
  let assert Ok(req) = request.from_uri(client.uri)
  req
  |> request.set_path(path)
  |> request.set_header("Content-Type", "application/json")
  |> set_auth(client.api_key)
}

fn set_auth(req: Request(String), api_key: Option(String)) -> Request(String) {
  case api_key {
    Some(key) -> req |> request.set_header("Authorization", "Bearer " <> key)
    None -> req
  }
}

pub fn send_request(
  request: Request(String),
  api_error_status_codes: List(Int),
  parser: fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) -> Result(MeilisearchResponse(a), Error) {
  case httpc.send(request) {
    Ok(response) -> {
      use body <- expect_success(response, api_error_status_codes)
      parser(response.status, body)
    }
    Error(http_error) -> Error(TransportError(http_error))
  }
}

// This function handles transport error.
// api_error_status is a list of status code that a Meilisearch endpoint uses to communicate
// a Meilisearch error. As an example, the create_index enpoint can return 401 with a body.
// The body contains a Meilisearch error. This is part of the protocol and will be handled by 
// the sans-io library.
// This function only handles transport error not related to Meilisearch such as 500
fn expect_success(
  response: Response(String),
  api_error_status: List(Int),
  next: fn(String) -> Result(response, Error),
) -> Result(response, Error) {
  let Response(status, _, body) = response
  let is_api_error = check_if_status_is_api_error(status, api_error_status)
  case status {
    _ if is_api_error == True -> next(body)
    _ if status >= 400 -> Error(UnexpectedHttpStatusCodeError(status:, body:))
    _ -> next(body)
  }
}

fn check_if_status_is_api_error(error: Int, errors: List(Int)) -> Bool {
  errors
  |> list.contains(any: error)
}
