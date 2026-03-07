//// Typing

import gleam/option.{type Option}
import gleam/uri

pub type Client {
  Client(uri: uri.Uri, api_key: Option(String))
}

pub type Error {
  Uri
}
