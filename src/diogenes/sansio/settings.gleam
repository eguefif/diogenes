import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  MeilisearchSingleResult, UnexpectedHttpStatusCodeError,
  meilisearch_error_from_json, task_parser,
}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/json
import gleam/option.{type Option}
import gleam/result
import internal/http_tooling.{create_base_request}

// Api functions ---------------------------------------------------------------------------

/// Builds a request to retrieve the embedders setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Dict(String, Embedder))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_embedders(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-embedders
pub fn get_embedders(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Dict(String, Embedder)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/embedders",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case embedders_from_json(body) {
          Ok(embedders) -> Ok(MeilisearchSingleResult(embedders))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }

  #(request, parser)
}

/// Builds a request to update the embedders setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_embedders(client, "movies", embedders)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-embedders
pub fn update_embedders(
  client: Client,
  index_uid: String,
  embedders: Dict(String, Embedder),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let body = embedders_to_json(embedders) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/embedders",
    )
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the embedders setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_embedders(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-embedders
pub fn reset_embedders(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/embedders",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to reset all settings for the given index to their default values.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_all_settings(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-settings
pub fn reset_all_settings(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings")
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve all settings for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Settings)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = list_all_settings(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-settings
pub fn list_all_settings(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Settings), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings")
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 -> settings_list_from_json(body)
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update settings for the given index.
///
/// Only fields present in `settings` are modified. The operation is
/// asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_all_settings(client, "movies", settings)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-settings
pub fn update_all_settings(
  client: Client,
  index_uid: String,
  settings: Settings,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let body = settings_list_to_json(settings)
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings")
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to retrieve the chat settings for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Chat)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_chat(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-chat
pub fn get_chat(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Chat), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode_chat()) {
          Ok(chat_params) -> Ok(MeilisearchSingleResult(chat_params))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the chat settings for the given index.
///
/// Configures how the index is presented to the LLM, including description,
/// document template, and search parameters. The operation is asynchronous —
/// Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_chat(client, "movies", chat_settings)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-chat
pub fn update_chat(
  client: Client,
  index_uid: String,
  chat_settings: Chat,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(json.to_string(chat_to_json(chat_settings)))
  #(request, task_parser)
}

/// Builds a request to reset the chat settings for the given index to their default values.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_chat(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-chat
pub fn reset_chat(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the dictionary setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_dictionary(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-dictionary
pub fn get_dictionary(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/dictionary",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(dictionary) -> Ok(MeilisearchSingleResult(dictionary))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the dictionary setting for the given index.
///
/// The dictionary is a list of custom words that Meilisearch treats as
/// distinct tokens during tokenization (e.g. `["J. R. R.", "W. E. B."]`).
/// Send `null` to reset to the default. The operation is asynchronous —
/// Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_dictionary(client, "movies", ["J. R. R."])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-dictionary
pub fn update_dictionary(
  client: Client,
  index_uid: String,
  dictionnary: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(dictionnary, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/dictionary",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the dictionary setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_dictionary(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-dictionary
pub fn reset_dictionary(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/dictionary",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the displayed attributes setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_displayed_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-displayed-attributes
pub fn get_displayed_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/displayed-attributes",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(attributes) -> Ok(MeilisearchSingleResult(attributes))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the displayed attributes setting for the given index.
///
/// Displayed attributes are the fields returned in search results. The operation
/// is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_displayed_attributes(client, "movies", ["title", "overview"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-displayed-attributes
pub fn update_displayed_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(attributes, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/displayed-attributes",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the displayed attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_displayed_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-displayed-attributes
pub fn reset_displayed_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/displayed-attributes",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the searchable attributes setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_searchable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-searchable-attributes
pub fn get_searchable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/searchable-attributes",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(attributes) -> Ok(MeilisearchSingleResult(attributes))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the searchable attributes setting for the given index.
///
/// Searchable attributes are the fields Meilisearch searches through when
/// processing a query. The operation is asynchronous — Meilisearch enqueues it
/// and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_searchable_attributes(client, "movies", ["title", "overview"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-searchable-attributes
pub fn update_searchable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(attributes, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/searchable-attributes",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the searchable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_searchable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-searchable-attributes
pub fn reset_searchable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/searchable-attributes",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the sortable attributes setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_sortable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-sortable-attributes
pub fn get_sortable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/sortable-attributes",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(attributes) -> Ok(MeilisearchSingleResult(attributes))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the sortable attributes setting for the given index.
///
/// Sortable attributes are the fields that can be used to sort search results.
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_sortable_attributes(client, "movies", ["release_date", "title"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-sortable-attributes
pub fn update_sortable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(attributes, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/sortable-attributes",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the sortable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_sortable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-sortable-attributes
pub fn reset_sortable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/sortable-attributes",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the non-separator tokens setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_non_separator_tokens(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-non-separator-tokens
pub fn get_non_separator_tokens(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/non-separator-tokens",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(tokens) -> Ok(MeilisearchSingleResult(tokens))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the non-separator tokens setting for the given index.
///
/// Non-separator tokens are characters that Meilisearch should not treat as
/// word separators during tokenization. The operation is asynchronous —
/// Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_non_separator_tokens(client, "movies", ["@", "#"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-non-separator-tokens
pub fn update_non_separator_tokens(
  client: Client,
  index_uid: String,
  tokens: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(tokens, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/non-separator-tokens",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the non-separator tokens setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_non_separator_tokens(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-non-separator-tokens
pub fn reset_non_separator_tokens(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/non-separator-tokens",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the separator tokens setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_separator_tokens(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-separator-tokens
pub fn get_separator_tokens(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/separator-tokens",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(tokens) -> Ok(MeilisearchSingleResult(tokens))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the separator tokens setting for the given index.
///
/// Separator tokens are characters that Meilisearch treats as word separators
/// during tokenization. The operation is asynchronous — Meilisearch enqueues
/// it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_separator_tokens(client, "movies", ["|", "/"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-separator-tokens
pub fn update_separator_tokens(
  client: Client,
  index_uid: String,
  tokens: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(tokens, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/separator-tokens",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the separator tokens setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_separator_tokens(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-separator-tokens
pub fn reset_separator_tokens(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/separator-tokens",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the stop words setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_stop_words(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-stop-words
pub fn get_stop_words(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/stop-words",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(words) -> Ok(MeilisearchSingleResult(words))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the stop words setting for the given index.
///
/// Stop words are words ignored by Meilisearch during search (e.g. "the", "a").
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_stop_words(client, "movies", ["the", "a", "an"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-stop-words
pub fn update_stop_words(
  client: Client,
  index_uid: String,
  words: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(words, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/stop-words",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the stop words setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_stop_words(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-stop-words
pub fn reset_stop_words(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/stop-words",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the filterable attributes setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_filterable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-filterable-attributes
pub fn get_filterable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/filterable-attributes",
    )
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.list(decode.string)) {
          Ok(attributes) -> Ok(MeilisearchSingleResult(attributes))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the filterable attributes setting for the given index.
///
/// Filterable attributes are the fields that can be used in filter expressions
/// during search. The operation is asynchronous — Meilisearch enqueues it and
/// returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_filterable_attributes(client, "movies", ["genre", "year"])
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-filterable-attributes
pub fn update_filterable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(attributes, json.string) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/filterable-attributes",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the filterable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_filterable_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-filterable-attributes
pub fn reset_filterable_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/filterable-attributes",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the ranking rules setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(RankingRule))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_ranking_rules(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-ranking-rules
pub fn get_ranking_rules(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(List(RankingRule)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/ranking-rules",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode_ranking_rules()) {
          Ok(ranking_rules) -> Ok(MeilisearchSingleResult(ranking_rules))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }

  #(request, parser)
}

/// Builds a request to update the ranking rules setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_ranking_rules(client, "movies", ranking_rules)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-ranking-rules
pub fn update_ranking_rules(
  client: Client,
  index_uid: String,
  ranking_rules: List(RankingRule),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(ranking_rules, ranking_rule_to_json) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/ranking-rules",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the ranking rules setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_ranking_rules(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-ranking-rules
pub fn reset_ranking_rules(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/ranking-rules",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the search cutoff ms setting for the given index.
///
/// `searchCutoffMs` defines the maximum time in milliseconds Meilisearch will
/// spend processing a search request before returning the best results found so far.
/// The default value is `0` (no cutoff).
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Int)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_search_cutoff_ms(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-search-cutoff-ms
pub fn get_search_cutoff_ms(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(option.Option(Int)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/search-cutoff-ms",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.optional(decode.int)) {
          Ok(cutoff) -> Ok(MeilisearchSingleResult(cutoff))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the search cutoff ms setting for the given index.
///
/// `searchCutoffMs` defines the maximum time in milliseconds Meilisearch will
/// spend processing a search request before returning the best results found so far.
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_search_cutoff_ms(client, "movies", 150)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-search-cutoff-ms
pub fn update_search_cutoff_ms(
  client: Client,
  index_uid: String,
  search_cutoff_ms: Int,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.int(search_cutoff_ms) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/search-cutoff-ms",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the search cutoff ms setting for the given index to its default value.
///
/// The default value is `0` (no cutoff).
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_search_cutoff_ms(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-search-cutoff-ms
pub fn reset_search_cutoff_ms(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/search-cutoff-ms",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the foreign keys setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(ForeignKey))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_foreign_keys(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-foreign-keys
pub fn get_foreign_keys(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) ->
    Result(MeilisearchResponse(option.Option(List(ForeignKey))), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/foreign-keys",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(body, decode.optional(decode.list(decode_foreign_keys())))
        {
          Ok(foreign_keys) -> Ok(MeilisearchSingleResult(foreign_keys))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the foreign keys setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_foreign_keys(client, "movies", foreign_keys)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-foreign-keys
pub fn update_foreign_keys(
  client: Client,
  index_uid: String,
  foreign_keys: List(ForeignKey),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.array(foreign_keys, foreign_key_to_json) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/foreign-keys",
    )
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the foreign keys setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_foreign_keys(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-foreign-keys
pub fn reset_foreign_keys(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/foreign-keys",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the prefix search setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(PrefixSearch)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_prefix_search(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-prefix-search
pub fn get_prefix_search(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(PrefixSearch), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/prefix-search",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(
            body,
            decode.string |> decode.map(prefix_search_from_string),
          )
        {
          Ok(prefix_search) -> Ok(MeilisearchSingleResult(prefix_search))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the prefix search setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_prefix_search(client, "movies", IndexTime)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-prefix-search
pub fn update_prefix_search(
  client: Client,
  index_uid: String,
  prefix_search: option.Option(PrefixSearch),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = prefix_search_to_json(prefix_search) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/prefix-search",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the prefix search setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_prefix_search(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-prefix-search
pub fn reset_prefix_search(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/prefix-search",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the proximity precision setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(ProximityPrecision)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_proximity_precision(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-proximity-precision
pub fn get_proximity_precision(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(ProximityPrecision), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/proximity-precision",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(
            body,
            decode.string |> decode.map(proximity_precision_from_string),
          )
        {
          Ok(precision) -> Ok(MeilisearchSingleResult(precision))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the proximity precision setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_proximity_precision(client, "movies", ByWord)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-proximity-precision
pub fn update_proximity_precision(
  client: Client,
  index_uid: String,
  proximity_precision: ProximityPrecision,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = proximity_precision_to_json(proximity_precision) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/proximity-precision",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the proximity precision setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_proximity_precision(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-proximity-precision
pub fn reset_proximity_precision(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/proximity-precision",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the localized attributes setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(List(LocalizedAttribute))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_localized_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-localized-attributes
pub fn get_localized_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) ->
    Result(MeilisearchResponse(option.Option(List(LocalizedAttribute))), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/localized-attributes",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(
            body,
            decode.optional(decode.list(decode_localized_attribute())),
          )
        {
          Ok(attributes) -> Ok(MeilisearchSingleResult(attributes))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the localized attributes setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_localized_attributes(client, "movies", attributes)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-localized-attributes
pub fn update_localized_attributes(
  client: Client,
  index_uid: String,
  attributes: List(LocalizedAttribute),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body =
    json.array(attributes, localized_attribute_to_json) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/localized-attributes",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the localized attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_localized_attributes(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-localized-attributes
pub fn reset_localized_attributes(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/localized-attributes",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the pagination setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Pagination)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_pagination(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-pagination
pub fn get_pagination(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Pagination), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/pagination",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(body, {
            use max_total_hits <- decode.field("maxTotalHits", decode.int)
            decode.success(Pagination(max_total_hits:))
          })
        {
          Ok(pagination) -> Ok(MeilisearchSingleResult(pagination))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the pagination setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_pagination(client, "movies", pagination)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-pagination
pub fn update_pagination(
  client: Client,
  index_uid: String,
  pagination: Pagination,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = pagination_to_json(pagination) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/pagination",
    )
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the pagination setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_pagination(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-pagination
pub fn reset_pagination(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/pagination",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the faceting setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Faceting)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_faceting(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-faceting
pub fn get_faceting(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Faceting), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/faceting",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode_faceting()) {
          Ok(faceting) -> Ok(MeilisearchSingleResult(faceting))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the faceting setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_faceting(client, "movies", faceting)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-faceting
pub fn update_faceting(
  client: Client,
  index_uid: String,
  faceting: Faceting,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = faceting_to_json(faceting) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/faceting",
    )
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the faceting setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_faceting(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-faceting
pub fn reset_faceting(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/faceting",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the typo tolerance setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(TypoTolerance)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_typo_tolerance(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-typo-tolerance
pub fn get_typo_tolerance(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(TypoTolerance), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/typo-tolerance",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode_typo_tolerance_decoder()) {
          Ok(typo_tolerance) -> Ok(MeilisearchSingleResult(typo_tolerance))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the typo tolerance setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_typo_tolerance(client, "movies", typo_tolerance)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-typo-tolerance
pub fn update_typo_tolerance(
  client: Client,
  index_uid: String,
  typo_tolerance: TypoTolerance,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = typo_tolerance_to_json(typo_tolerance) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/typo-tolerance",
    )
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the typo tolerance setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_typo_tolerance(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-typo-tolerance
pub fn reset_typo_tolerance(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/typo-tolerance",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the synonyms setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Dict(String, List(String)))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_synonyms(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-synonyms
pub fn get_synonyms(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) ->
    Result(MeilisearchResponse(dict.Dict(String, List(String))), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/synonyms",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case
          json.parse(
            body,
            decode.dict(decode.string, decode.list(decode.string)),
          )
        {
          Ok(synonyms) -> Ok(MeilisearchSingleResult(synonyms))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the synonyms setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_synonyms(client, "movies", dict.from_list([#("wolverine", ["xmen", "logan"])]))
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-synonyms
pub fn update_synonyms(
  client: Client,
  index_uid: String,
  synonyms: dict.Dict(String, List(String)),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body =
    json.dict(synonyms, fn(k) { k }, fn(v) { json.array(v, json.string) })
    |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/synonyms",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the synonyms setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_synonyms(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-synonyms
pub fn reset_synonyms(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/synonyms",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the distinct attribute setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Option(String))`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_distinct_attribute(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-distinct-attribute
pub fn get_distinct_attribute(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(option.Option(String)), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/distinct-attribute",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.optional(decode.string)) {
          Ok(attribute) -> Ok(MeilisearchSingleResult(attribute))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the distinct attribute setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_distinct_attribute(client, "movies", "movie_id")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-distinct-attribute
pub fn update_distinct_attribute(
  client: Client,
  index_uid: String,
  distinct_attribute: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.string(distinct_attribute) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/distinct-attribute",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the distinct attribute setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_distinct_attribute(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-distinct-attribute
pub fn reset_distinct_attribute(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/distinct-attribute",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

/// Builds a request to retrieve the facet search setting for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Bool)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_facet_search(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/get-facet-search
pub fn get_facet_search(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Bool), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/facet-search",
    )
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode.bool) {
          Ok(enabled) -> Ok(MeilisearchSingleResult(enabled))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the facet search setting for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_facet_search(client, "movies", True)
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/update-facet-search
pub fn update_facet_search(
  client: Client,
  index_uid: String,
  facet_search: Bool,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body = json.bool(facet_search) |> json.to_string
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/facet-search",
    )
    |> request.set_method(http.Put)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to reset the facet search setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_facet_search(client, "movies")
/// ```
///
/// ## Reference
/// https://www.meilisearch.com/docs/reference/api/settings/reset-facet-search
pub fn reset_facet_search(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/settings/facet-search",
    )
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

// Types ---------------------------------------------------------------------------------------------

pub type Settings {
  Settings(
    displayed_attributes: List(String),
    searchable_attributes: List(String),
    // TODO: fiterable_attributes can also be object
    filterable_attributes: List(String),
    sortable_attributes: List(String),
    foreign_keys: option.Option(List(ForeignKey)),
    ranking_rules: List(RankingRule),
    stop_words: List(String),
    non_separator_tokens: List(String),
    separator_tokens: List(String),
    dictionary: List(String),
    synonyms: Dict(String, List(String)),
    distinct_attribute: option.Option(String),
    proximity_precision: ProximityPrecision,
    typo_tolerance: TypoTolerance,
    faceting: Faceting,
    pagination: Pagination,
    embedders: Dict(String, Embedder),
    search_cutoff_ms: option.Option(Int),
    localized_attribute: option.Option(List(LocalizedAttribute)),
    facet_search: Bool,
    prefix_search: option.Option(PrefixSearch),
    chat: option.Option(Chat),
  )
}

pub type ForeignKey {
  ForeignKey(foreign_index_uid: String, field_name: String)
}

pub type PrefixSearch {
  IndexingTime
  PrefixSearchDisabled
  UnexpectedPrefixSearch
}

pub type LocalizedAttribute {
  LocalizedAttribute(locales: List(Locales), attribute_patterns: List(String))
}

pub type RankingRule {
  Words
  Typo
  Proximity
  AttributeRank
  Sort
  WordPosition
  Exactness
  UnexpectedRule
}

pub type Pagination {
  Pagination(max_total_hits: Int)
}

pub type ProximityPrecision {
  ByWord
  ByAttribute
  UnexpectedProximityPrecision
}

pub type TypoTolerance {
  TypoTolerance(
    enabled: Bool,
    min_word_size_for_typo: MinWordSizeForTypo,
    disable_on_words: List(String),
    disable_on_attributes: List(String),
  )
}

pub type MinWordSizeForTypo {
  MinWordSizeForTypo(one_typo: Int, two_typos: Int)
}

pub type Faceting {
  Faceting(
    max_values_per_facet: Int,
    sort_facet_values_by: Dict(String, SortType),
  )
}

pub type SortType {
  Count
  Alpha
  UnexpectedSortType
}

pub type Embedder {
  Embedder(
    source: EmbedderSource,
    model: String,
    revision: option.Option(String),
    pooling: Option(EmbedderPooling),
    api_key: Option(String),
    dimensions: option.Option(Int),
    binary_quantisized: Option(Bool),
    document_template: String,
    document_template_max_bytes: option.Option(Int),
    url: option.Option(String),
    // TODO: for the following dicts Value in following dict is any
    indexing_fragments: option.Option(Dict(String, String)),
    search_fragments: option.Option(Dict(String, String)),
    request: Option(Dict(String, String)),
    response: Option(Dict(String, String)),
    // Not for this one
    headers: Option(Dict(String, String)),
    search_embedder: option.Option(Embedder),
    indexing_embedder: option.Option(Embedder),
    distribution: option.Option(Distribution),
  )
}

pub type EmbedderSource {
  OpenAi
  HuggingFace
  Ollama
  Rest
  Composite
  UserProvided
  UnexpectedSource
}

pub type EmbedderPooling {
  UseModel
  ForceCls
  ForceMean
  UnexpectedPooling
}

pub type Distribution {
  Distribution(mean: Float, sigma: Float)
}

pub type Chat {
  Chat(
    description: String,
    document_template: String,
    document_template_max_bytes: Int,
    search_parameters: ChatSearchParameters,
  )
}

pub type ChatSearchParameters {
  ChatSearchParameters(
    hybrid: ChatEmbedder,
    limit: Int,
    sort: List(String),
    distinct: String,
    matching_strategy: ChatMatchingStrategy,
    attributes_to_search_on: List(String),
    ranking_score_threshold: option.Option(Float),
  )
}

pub type ChatEmbedder {
  ChatEmbedder(embedder: String, semantic_ratio: Float)
}

pub type ChatMatchingStrategy {
  Last
  All
  Frequency
  UnexpectedChatMatchingStrategy
}

// Settings decoding function/json --------------------------------------------------------------------------

fn settings_list_from_json(
  settings: String,
) -> Result(MeilisearchResponse(Settings), Error) {
  json.parse(settings, decode_settings())
  |> result.map(MeilisearchSingleResult)
  |> result.map_error(JsonError)
}

fn decode_settings() -> decode.Decoder(Settings) {
  use displayed_attributes <- decode.field(
    "displayedAttributes",
    decode.list(decode.string),
  )
  use searchable_attributes <- decode.field(
    "searchableAttributes",
    decode.list(decode.string),
  )
  use filterable_attributes <- decode.field(
    "filterableAttributes",
    decode.list(decode.string),
  )
  use sortable_attributes <- decode.field(
    "sortableAttributes",
    decode.list(decode.string),
  )
  use foreign_keys <- decode.optional_field(
    "foreignKeys",
    option.None,
    decode.optional(decode.list(decode_foreign_keys())),
  )
  use ranking_rules <- decode.field("rankingRules", decode_ranking_rules())
  use stop_words <- decode.field("stopWords", decode.list(decode.string))
  use non_separator_tokens <- decode.field(
    "nonSeparatorTokens",
    decode.list(decode.string),
  )
  use separator_tokens <- decode.field(
    "separatorTokens",
    decode.list(decode.string),
  )
  use dictionary <- decode.field("dictionary", decode.list(decode.string))
  use synonyms <- decode.field(
    "synonyms",
    decode.dict(decode.string, decode.list(decode.string)),
  )
  use distinct_attribute <- decode.field(
    "distinctAttribute",
    decode.optional(decode.string),
  )
  use proximity_precision <- decode.field(
    "proximityPrecision",
    decode.string
      |> decode.map(fn(value) { proximity_precision_from_string(value) }),
  )
  use typo_tolerance <- decode.field(
    "typoTolerance",
    decode_typo_tolerance_decoder(),
  )
  use faceting <- decode.field("faceting", decode_faceting())
  use pagination <- decode.field("pagination", {
    use max_total_hits <- decode.field("maxTotalHits", decode.int)
    decode.success(Pagination(max_total_hits:))
  })

  use embedders <- decode.field("embedders", decode_embedders())
  use search_cutoff_ms <- decode.field(
    "searchCutoffMs",
    decode.optional(decode.int),
  )
  use localized_attribute <- decode.field(
    "localizedAttributes",
    decode.optional(decode.list(decode_localized_attribute())),
  )
  use facet_search <- decode.field("facetSearch", decode.bool)
  use prefix_search <- decode.field(
    "prefixSearch",
    decode.optional(decode.string |> decode.map(prefix_search_from_string)),
  )
  use chat <- decode.optional_field(
    "chat",
    option.None,
    decode_chat() |> decode.map(option.Some),
  )

  decode.success(Settings(
    displayed_attributes:,
    searchable_attributes:,
    filterable_attributes:,
    sortable_attributes:,
    foreign_keys:,
    ranking_rules:,
    stop_words:,
    non_separator_tokens:,
    separator_tokens:,
    dictionary:,
    synonyms:,
    distinct_attribute:,
    proximity_precision:,
    typo_tolerance:,
    faceting:,
    pagination:,
    embedders:,
    search_cutoff_ms:,
    localized_attribute:,
    facet_search:,
    prefix_search:,
    chat:,
  ))
}

fn settings_list_to_json(settings: Settings) -> String {
  let params = [
    #(
      "displayedAttributes",
      json.array(settings.displayed_attributes, json.string),
    ),
    #(
      "searchableAttributes",
      json.array(settings.searchable_attributes, json.string),
    ),
    #(
      "filterableAttributes",
      json.array(settings.filterable_attributes, json.string),
    ),
    #(
      "sortableAttributes",
      json.array(settings.sortable_attributes, json.string),
    ),
    #("rankingRules", json.array(settings.ranking_rules, ranking_rule_to_json)),
    #("stopWords", json.array(settings.stop_words, json.string)),
    #(
      "nonSeparatorTokens",
      json.array(settings.non_separator_tokens, json.string),
    ),
    #("separatorTokens", json.array(settings.separator_tokens, json.string)),
    #("dictionary", json.array(settings.dictionary, json.string)),
    #(
      "synonyms",
      json.dict(settings.synonyms, fn(v) { v }, fn(v) {
        json.array(v, json.string)
      }),
    ),
    #("distinctAttribute", case settings.distinct_attribute {
      option.Some(attr) -> json.string(attr)
      option.None -> json.null()
    }),
    #(
      "proximityPrecision",
      proximity_precision_to_json(settings.proximity_precision),
    ),
    #("typoTolerance", typo_tolerance_to_json(settings.typo_tolerance)),
    #("faceting", faceting_to_json(settings.faceting)),
    #("pagination", pagination_to_json(settings.pagination)),
    #("embedders", embedders_to_json(settings.embedders)),
    #("searchCutoffMs", case settings.search_cutoff_ms {
      option.Some(search_cutoff_ms) -> json.int(search_cutoff_ms)
      option.None -> json.null()
    }),
    #("localizedAttributes", case settings.localized_attribute {
      option.Some(attrs) -> json.array(attrs, localized_attribute_to_json)
      option.None -> json.null()
    }),
    #("facetSearch", json.bool(settings.facet_search)),
    #("prefixSearch", prefix_search_to_json(settings.prefix_search)),
  ]

  let params = case settings.foreign_keys {
    option.Some(keys) -> [
      #("foreignKeys", json.array(keys, foreign_key_to_json)),
      ..params
    ]
    option.None -> params
  }

  let params = case settings.chat {
    option.Some(chat) -> [#("chat", chat_to_json(chat)), ..params]
    option.None -> params
  }

  json.object(params) |> json.to_string
}

fn prefix_search_from_string(value: String) -> PrefixSearch {
  case value {
    "indexingTime" -> IndexingTime
    "disabled" -> PrefixSearchDisabled
    _ -> UnexpectedPrefixSearch
  }
}

fn prefix_search_to_json(
  prefix_search: option.Option(PrefixSearch),
) -> json.Json {
  case prefix_search {
    option.Some(IndexingTime) -> json.string("indexingTime")
    option.Some(PrefixSearchDisabled) -> json.string("disabled")
    _ -> json.null()
  }
}

fn pagination_to_json(pagination: Pagination) -> json.Json {
  json.object([#("maxTotalHits", json.int(pagination.max_total_hits))])
}

fn decode_foreign_keys() -> decode.Decoder(ForeignKey) {
  use foreign_index_uid <- decode.field("foreignIndexUid", decode.string)
  use field_name <- decode.field("fieldName", decode.string)

  decode.success(ForeignKey(foreign_index_uid:, field_name:))
}

fn foreign_key_to_json(foreign_key: ForeignKey) -> json.Json {
  json.object([
    #("foreignIndexUid", json.string(foreign_key.foreign_index_uid)),
    #("fieldName", json.string(foreign_key.field_name)),
  ])
}

fn decode_localized_attribute() -> decode.Decoder(LocalizedAttribute) {
  use locales <- decode.field(
    "locales",
    decode.list(
      decode.string
      |> decode.map(locales_from_string),
    ),
  )
  use attribute_patterns <- decode.field(
    "attributePatterns",
    decode.list(decode.string),
  )

  decode.success(LocalizedAttribute(locales:, attribute_patterns:))
}

fn localized_attribute_to_json(
  localized_attribute: LocalizedAttribute,
) -> json.Json {
  json.object([
    #("locales", json.array(localized_attribute.locales, locales_to_json)),
    #(
      "attributePatterns",
      json.array(localized_attribute.attribute_patterns, json.string),
    ),
  ])
}

fn embedders_from_json(
  body: String,
) -> Result(Dict(String, Embedder), json.DecodeError) {
  json.parse(body, decode_embedders())
}

fn decode_embedders() -> decode.Decoder(Dict(String, Embedder)) {
  use embedders <- decode.then(decode.dict(decode.string, decode_embedder()))

  decode.success(embedders)
}

fn decode_embedder() -> decode.Decoder(Embedder) {
  use <- decode.recursive
  use source <- decode.field(
    "source",
    decode.string |> decode.map(decode_source),
  )
  use model <- decode.field("model", decode.string)
  use revision <- decode.optional_field(
    "revision",
    option.None,
    decode.optional(decode.string),
  )
  use pooling <- decode.optional_field(
    "pooling",
    option.None,
    decode.optional(decode.string |> decode.map(decode_pooling)),
  )
  use api_key <- decode.optional_field(
    "apiKey",
    option.None,
    decode.optional(decode.string),
  )
  use dimensions <- decode.optional_field(
    "dimensions",
    option.None,
    decode.optional(decode.int),
  )
  use binary_quantisized <- decode.optional_field(
    "binaryQuantisized",
    option.None,
    decode.optional(decode.bool),
  )
  use document_template <- decode.field("documentTemplate", decode.string)
  use document_template_max_bytes <- decode.optional_field(
    "documentTemplateMaxBytes",
    option.None,
    decode.optional(decode.int),
  )
  use url <- decode.optional_field(
    "url",
    option.None,
    decode.optional(decode.string),
  )
  use indexing_fragments <- decode.optional_field(
    "indexingFragments",
    option.None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use search_fragments <- decode.optional_field(
    "searchFragments",
    option.None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use request <- decode.optional_field(
    "request",
    option.None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use response <- decode.optional_field(
    "response",
    option.None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use headers <- decode.optional_field(
    "headers",
    option.None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use search_embedder <- decode.optional_field(
    "searchEmbedder",
    option.None,
    decode.optional(decode_embedder()),
  )
  use indexing_embedder <- decode.optional_field(
    "indexingEmbedder",
    option.None,
    decode.optional(decode_embedder()),
  )
  use distribution <- decode.optional_field("distribution", option.None, {
    use mean <- decode.field("mean", decode.float)
    use sigma <- decode.field("sigma", decode.float)
    decode.success(option.Some(Distribution(mean:, sigma:)))
  })

  decode.success(Embedder(
    source:,
    model:,
    revision:,
    pooling:,
    api_key:,
    dimensions:,
    binary_quantisized:,
    document_template:,
    document_template_max_bytes:,
    url:,
    indexing_fragments:,
    search_fragments:,
    request:,
    response:,
    headers:,
    search_embedder:,
    indexing_embedder:,
    distribution:,
  ))
}

fn decode_pooling(value: String) -> EmbedderPooling {
  case value {
    "useModel" -> UseModel
    "forceCls" -> ForceCls
    "forceMean" -> ForceMean
    _ -> UnexpectedPooling
  }
}

fn decode_source(value: String) -> EmbedderSource {
  case value {
    "openAi" -> OpenAi
    "huggingFace" -> HuggingFace
    "ollama" -> Ollama
    "rest" -> Rest
    "composite" -> Composite
    "userProvided" -> UserProvided
    _ -> UnexpectedSource
  }
}

fn embedders_to_json(embedders: Dict(String, Embedder)) -> json.Json {
  json.dict(embedders, fn(k) { k }, fn(v) { embedder_to_json(v) })
}

fn embedder_to_json(embedder: Embedder) -> json.Json {
  let params = [
    #("source", embedder_source_to_json(embedder.source)),
    #("model", json.string(embedder.model)),
    #("apiKey", case embedder.api_key {
      option.None -> json.null()
      option.Some(key) -> json.string(key)
    }),
    #("dimensions", case embedder.dimensions {
      option.Some(dimensions) -> json.int(dimensions)
      option.None -> json.null()
    }),
    #("binaryQuantized", case embedder.binary_quantisized {
      option.Some(binary_quantisized) -> json.bool(binary_quantisized)
      option.None -> json.null()
    }),
    #("documentTemplate", json.string(embedder.document_template)),
    #("url", case embedder.url {
      option.Some(url) -> json.string(url)
      option.None -> json.null()
    }),
  ]

  let params = case embedder.document_template_max_bytes {
    option.Some(max_bytes) -> [
      #("documentTemplateMaxBytes", json.int(max_bytes)),
      ..params
    ]
    option.None -> params
  }
  let params = case embedder.revision {
    option.Some(revision) -> [#("revision", json.string(revision)), ..params]
    option.None -> params
  }
  let params = case embedder.pooling {
    option.Some(pooling) -> [#("pooling", pooling_to_json(pooling)), ..params]
    option.None -> params
  }
  let params = case embedder.distribution {
    option.Some(distribution) -> [
      #("distribution", distribution_to_json(distribution)),
      ..params
    ]
    option.None -> params
  }

  let params = case embedder.indexing_fragments {
    option.Some(indexing_fragments) -> [
      #(
        "indexingFragments",
        json.dict(indexing_fragments, fn(k) { k }, fn(v) { json.string(v) }),
      ),
      ..params
    ]
    option.None -> params
  }

  let params = case embedder.search_fragments {
    option.Some(search_fragments) -> [
      #(
        "searchFragments",
        json.dict(search_fragments, fn(k) { k }, fn(v) { json.string(v) }),
      ),
      ..params
    ]
    option.None -> params
  }

  let params = case embedder.request {
    option.None -> params
    option.Some(request) -> [
      #("request", json.dict(request, fn(k) { k }, fn(v) { json.string(v) })),
      ..params
    ]
  }
  let params = case embedder.response {
    option.None -> params
    option.Some(response) -> [
      #("response", json.dict(response, fn(k) { k }, fn(v) { json.string(v) })),
      ..params
    ]
  }

  let params = case embedder.headers {
    option.None -> params
    option.Some(headers) -> [
      #("headers", json.dict(headers, fn(k) { k }, fn(v) { json.string(v) })),
      ..params
    ]
  }
  let params = case embedder.search_embedder {
    option.Some(search_embedder) -> [
      #("search_embedder", embedder_to_json(search_embedder)),
      ..params
    ]
    option.None -> params
  }
  let params = case embedder.indexing_embedder {
    option.Some(indexing_embedder) -> [
      #("indexing_embedder", embedder_to_json(indexing_embedder)),
      ..params
    ]
    option.None -> params
  }

  json.object(params)
}

fn pooling_to_json(pooling: EmbedderPooling) -> json.Json {
  case pooling {
    UseModel -> json.string("useModel")
    ForceCls -> json.string("forceCls")
    ForceMean -> json.string("forceMean")
    UnexpectedPooling -> json.null()
  }
}

fn embedder_source_to_json(source: EmbedderSource) -> json.Json {
  case source {
    OpenAi -> json.string("openAi")
    HuggingFace -> json.string("huggingFace")
    Ollama -> json.string("ollama")
    Rest -> json.string("rest")
    Composite -> json.string("composite")
    UserProvided -> json.string("userProvided")
    UnexpectedSource -> json.null()
  }
}

fn distribution_to_json(distribution: Distribution) -> json.Json {
  json.object([
    #("mean", json.float(distribution.mean)),
    #("sigma", json.float(distribution.sigma)),
  ])
}

fn decode_chat() -> decode.Decoder(Chat) {
  use description <- decode.field("description", decode.string)
  use document_template <- decode.field("documentTemplate", decode.string)
  use document_template_max_bytes <- decode.field(
    "documentTemplateMaxBytes",
    decode.int,
  )
  use search_parameters <- decode.field(
    "searchParameters",
    decode_chat_search_parameters(),
  )
  decode.success(Chat(
    description:,
    document_template:,
    document_template_max_bytes:,
    search_parameters:,
  ))
}

fn decode_chat_search_parameters() -> decode.Decoder(ChatSearchParameters) {
  use hybrid <- decode.field("hybrid", decode_chat_embedder())
  use limit <- decode.field("limit", decode.int)
  use sort <- decode.field("sort", decode.list(decode.string))
  use distinct <- decode.field("distinct", decode.string)
  use matching_strategy <- decode.field(
    "matchingStrategy",
    decode.string |> decode.map(chat_matching_strategy_from_string),
  )
  use attributes_to_search_on <- decode.field(
    "attributesToSearchOn",
    decode.list(decode.string),
  )
  use ranking_score_threshold <- decode.field(
    "rankingScoreThreshold",
    decode.optional(decode.float),
  )
  decode.success(ChatSearchParameters(
    hybrid:,
    limit:,
    sort:,
    distinct:,
    matching_strategy:,
    attributes_to_search_on:,
    ranking_score_threshold:,
  ))
}

fn decode_chat_embedder() -> decode.Decoder(ChatEmbedder) {
  use embedder <- decode.field("embedder", decode.string)
  use semantic_ratio <- decode.field("semanticRatio", decode.float)
  decode.success(ChatEmbedder(embedder:, semantic_ratio:))
}

fn chat_matching_strategy_from_string(value: String) -> ChatMatchingStrategy {
  case value {
    "last" -> Last
    "all" -> All
    "frequency" -> Frequency
    _ -> UnexpectedChatMatchingStrategy
  }
}

fn chat_to_json(chat: Chat) -> json.Json {
  json.object([
    #("description", json.string(chat.description)),
    #("documentTemplate", json.string(chat.document_template)),
    #("documentTemplateMaxBytes", json.int(chat.document_template_max_bytes)),
    #(
      "searchParameters",
      chat_search_parameters_to_json(chat.search_parameters),
    ),
  ])
}

fn chat_search_parameters_to_json(params: ChatSearchParameters) -> json.Json {
  json.object([
    #("hybrid", chat_embedder_to_json(params.hybrid)),
    #("limit", json.int(params.limit)),
    #("sort", json.array(params.sort, json.string)),
    #("distinct", json.string(params.distinct)),
    #(
      "matchingStrategy",
      chat_matching_strategy_to_json(params.matching_strategy),
    ),
    #(
      "attributesToSearchOn",
      json.array(params.attributes_to_search_on, json.string),
    ),
    #("rankingScoreThreshold", case params.ranking_score_threshold {
      option.Some(ranking_score_threshold) ->
        json.float(ranking_score_threshold)
      option.None -> json.null()
    }),
  ])
}

fn chat_embedder_to_json(chat_embedder: ChatEmbedder) -> json.Json {
  json.object([
    #("embedder", json.string(chat_embedder.embedder)),
    #("semanticRatio", json.float(chat_embedder.semantic_ratio)),
  ])
}

fn chat_matching_strategy_to_json(strategy: ChatMatchingStrategy) -> json.Json {
  case strategy {
    Last -> json.string("last")
    All -> json.string("all")
    Frequency -> json.string("frequency")
    UnexpectedChatMatchingStrategy -> json.null()
  }
}

fn decode_faceting() -> decode.Decoder(Faceting) {
  use max_values_per_facet <- decode.field("maxValuesPerFacet", decode.int)
  use sort_facet_values_by <- decode.field(
    "sortFacetValuesBy",
    decode.dict(
      decode.string,
      decode.string
        |> decode.map(fn(value) {
          case value {
            "count" -> Count
            "alpha" -> Alpha
            _ -> UnexpectedSortType
          }
        }),
    ),
  )
  decode.success(Faceting(max_values_per_facet:, sort_facet_values_by:))
}

fn faceting_to_json(faceting: Faceting) -> json.Json {
  json.object([
    #("maxValuesPerFacet", json.int(faceting.max_values_per_facet)),
    #(
      "sortFacetValuesBy",
      json.dict(faceting.sort_facet_values_by, fn(k) { k }, fn(v) {
        case v {
          Count -> json.string("count")
          Alpha -> json.string("alpha")
          UnexpectedSortType -> json.null()
        }
      }),
    ),
  ])
}

fn decode_ranking_rules() -> decode.Decoder(List(RankingRule)) {
  decode.list(
    decode.string
    |> decode.map(fn(value) { ranking_rule_from_string(value) }),
  )
}

fn ranking_rule_from_string(ranking_rule: String) -> RankingRule {
  case ranking_rule {
    "words" -> Words
    "typo" -> Typo
    "proximity" -> Proximity
    "attributeRank" -> AttributeRank
    "sort" -> Sort
    "wordPosition" -> WordPosition
    "exactness" -> Exactness
    _ -> UnexpectedRule
  }
}

fn ranking_rule_to_json(ranking_rule: RankingRule) -> json.Json {
  case ranking_rule {
    Words -> json.string("words")
    Typo -> json.string("typo")
    Proximity -> json.string("proximity")
    AttributeRank -> json.string("attribute")
    Sort -> json.string("sort")
    WordPosition -> json.string("wordPosition")
    Exactness -> json.string("exactness")
    UnexpectedRule -> json.null()
  }
}

fn proximity_precision_from_string(
  proximity_precision: String,
) -> ProximityPrecision {
  case proximity_precision {
    "byWord" -> ByWord
    "byAttribute" -> ByAttribute
    _ -> UnexpectedProximityPrecision
  }
}

fn proximity_precision_to_json(
  proximity_precision: ProximityPrecision,
) -> json.Json {
  case proximity_precision {
    ByWord -> json.string("byWord")
    ByAttribute -> json.string("byAttribute")
    UnexpectedProximityPrecision -> json.null()
  }
}

fn decode_typo_tolerance_decoder() -> decode.Decoder(TypoTolerance) {
  {
    use enabled <- decode.field("enabled", decode.bool)
    use min_word_size_for_typo <- decode.field(
      "minWordSizeForTypos",
      min_word_size_for_typo_decoder(),
    )
    use disable_on_words <- decode.field(
      "disableOnWords",
      decode.list(decode.string),
    )
    use disable_on_attributes <- decode.field(
      "disableOnAttributes",
      decode.list(decode.string),
    )

    decode.success(TypoTolerance(
      enabled:,
      min_word_size_for_typo:,
      disable_on_words:,
      disable_on_attributes:,
    ))
  }
}

fn typo_tolerance_to_json(typo_tolerance: TypoTolerance) -> json.Json {
  json.object([
    #("enabled", json.bool(typo_tolerance.enabled)),
    #(
      "minWordSizeForTypos",
      json.object([
        #("oneTypo", json.int(typo_tolerance.min_word_size_for_typo.one_typo)),
        #("twoTypos", json.int(typo_tolerance.min_word_size_for_typo.two_typos)),
      ]),
    ),
    #(
      "disableOnWords",
      json.array(typo_tolerance.disable_on_words, json.string),
    ),
    #(
      "disableOnAttributes",
      json.array(typo_tolerance.disable_on_attributes, json.string),
    ),
  ])
}

fn min_word_size_for_typo_decoder() -> decode.Decoder(MinWordSizeForTypo) {
  use one_typo <- decode.field("oneTypo", decode.int)
  use two_typos <- decode.field("twoTypos", decode.int)

  decode.success(MinWordSizeForTypo(one_typo:, two_typos:))
}

// Locales Type, encoder, decoder ---------------------------------------------------------------

pub type Locales {
  Af
  Ak
  Am
  Ar
  Az
  Be
  Bn
  Bg
  Ca
  Cs
  Da
  De
  El
  En
  Eo
  Et
  Fi
  Fr
  Gu
  He
  Hi
  Hr
  Hu
  Hy
  Id
  It
  Jv
  Ja
  Kn
  Ka
  Km
  Ko
  La
  Lv
  Lt
  Ml
  Mr
  Mk
  My
  Ne
  Nl
  Nb
  Or
  Pa
  Fa
  Pl
  Pt
  Ro
  Ru
  Si
  Sk
  Sl
  Sn
  Es
  Sr
  Sv
  Ta
  Te
  Tl
  Th
  Tk
  Tr
  Uk
  Ur
  Uz
  Vi
  Yi
  Zh
  Zu
  Afr
  Aka
  Amh
  Ara
  Aze
  Bel
  Ben
  Bul
  Cat
  Ces
  Dan
  Deu
  Ell
  Eng
  Epo
  Est
  Fin
  Fra
  Guj
  Heb
  Hin
  Hrv
  Hun
  Hye
  Ind
  Ita
  Jav
  Jpn
  Kan
  Kat
  Khm
  Kor
  Lat
  Lav
  Lit
  Mal
  Mar
  Mkd
  Mya
  Nep
  Nld
  Nob
  Ori
  Pan
  Pes
  Pol
  Por
  Ron
  Rus
  Sin
  Slk
  Slv
  Sna
  Spa
  Srp
  Swe
  Tam
  Tel
  Tgl
  Tha
  Tuk
  Tur
  Ukr
  Urd
  Uzb
  Vie
  Yid
  Zho
  Zul
  Cmn
  UnexpectedLocal
}

pub fn locales_to_json(locale: Locales) -> json.Json {
  let local_string = case locale {
    Af -> "af"
    Ak -> "ak"
    Am -> "am"
    Ar -> "ar"
    Az -> "az"
    Be -> "be"
    Bn -> "bn"
    Bg -> "bg"
    Ca -> "ca"
    Cs -> "cs"
    Da -> "da"
    De -> "de"
    El -> "el"
    En -> "en"
    Eo -> "eo"
    Et -> "et"
    Fi -> "fi"
    Fr -> "fr"
    Gu -> "gu"
    He -> "he"
    Hi -> "hi"
    Hr -> "hr"
    Hu -> "hu"
    Hy -> "hy"
    Id -> "id"
    It -> "it"
    Jv -> "jv"
    Ja -> "ja"
    Kn -> "kn"
    Ka -> "ka"
    Km -> "km"
    Ko -> "ko"
    La -> "la"
    Lv -> "lv"
    Lt -> "lt"
    Ml -> "ml"
    Mr -> "mr"
    Mk -> "mk"
    My -> "my"
    Ne -> "ne"
    Nl -> "nl"
    Nb -> "nb"
    Or -> "or"
    Pa -> "pa"
    Fa -> "fa"
    Pl -> "pl"
    Pt -> "pt"
    Ro -> "ro"
    Ru -> "ru"
    Si -> "si"
    Sk -> "sk"
    Sl -> "sl"
    Sn -> "sn"
    Es -> "es"
    Sr -> "sr"
    Sv -> "sv"
    Ta -> "ta"
    Te -> "te"
    Tl -> "tl"
    Th -> "th"
    Tk -> "tk"
    Tr -> "tr"
    Uk -> "uk"
    Ur -> "ur"
    Uz -> "uz"
    Vi -> "vi"
    Yi -> "yi"
    Zh -> "zh"
    Zu -> "zu"
    Afr -> "afr"
    Aka -> "aka"
    Amh -> "amh"
    Ara -> "ara"
    Aze -> "aze"
    Bel -> "bel"
    Ben -> "ben"
    Bul -> "bul"
    Cat -> "cat"
    Ces -> "ces"
    Dan -> "dan"
    Deu -> "deu"
    Ell -> "ell"
    Eng -> "eng"
    Epo -> "epo"
    Est -> "est"
    Fin -> "fin"
    Fra -> "fra"
    Guj -> "guj"
    Heb -> "heb"
    Hin -> "hin"
    Hrv -> "hrv"
    Hun -> "hun"
    Hye -> "hye"
    Ind -> "ind"
    Ita -> "ita"
    Jav -> "jav"
    Jpn -> "jpn"
    Kan -> "kan"
    Kat -> "kat"
    Khm -> "khm"
    Kor -> "kor"
    Lat -> "lat"
    Lav -> "lav"
    Lit -> "lit"
    Mal -> "mal"
    Mar -> "mar"
    Mkd -> "mkd"
    Mya -> "mya"
    Nep -> "nep"
    Nld -> "nld"
    Nob -> "nob"
    Ori -> "ori"
    Pan -> "pan"
    Pes -> "pes"
    Pol -> "pol"
    Por -> "por"
    Ron -> "ron"
    Rus -> "rus"
    Sin -> "sin"
    Slk -> "slk"
    Slv -> "slv"
    Sna -> "sna"
    Spa -> "spa"
    Srp -> "srp"
    Swe -> "swe"
    Tam -> "tam"
    Tel -> "tel"
    Tgl -> "tgl"
    Tha -> "tha"
    Tuk -> "tuk"
    Tur -> "tur"
    Ukr -> "ukr"
    Urd -> "urd"
    Uzb -> "uzb"
    Vie -> "vie"
    Yid -> "yid"
    Zho -> "zho"
    Zul -> "zul"
    Cmn -> "cmn"
    UnexpectedLocal -> ""
  }
  json.string(local_string)
}

fn locales_from_string(value: String) -> Locales {
  case value {
    "af" -> Af
    "ak" -> Ak
    "am" -> Am
    "ar" -> Ar
    "az" -> Az
    "be" -> Be
    "bn" -> Bn
    "bg" -> Bg
    "ca" -> Ca
    "cs" -> Cs
    "da" -> Da
    "de" -> De
    "el" -> El
    "en" -> En
    "eo" -> Eo
    "et" -> Et
    "fi" -> Fi
    "fr" -> Fr
    "gu" -> Gu
    "he" -> He
    "hi" -> Hi
    "hr" -> Hr
    "hu" -> Hu
    "hy" -> Hy
    "id" -> Id
    "it" -> It
    "jv" -> Jv
    "ja" -> Ja
    "kn" -> Kn
    "ka" -> Ka
    "km" -> Km
    "ko" -> Ko
    "la" -> La
    "lv" -> Lv
    "lt" -> Lt
    "ml" -> Ml
    "mr" -> Mr
    "mk" -> Mk
    "my" -> My
    "ne" -> Ne
    "nl" -> Nl
    "nb" -> Nb
    "or" -> Or
    "pa" -> Pa
    "fa" -> Fa
    "pl" -> Pl
    "pt" -> Pt
    "ro" -> Ro
    "ru" -> Ru
    "si" -> Si
    "sk" -> Sk
    "sl" -> Sl
    "sn" -> Sn
    "es" -> Es
    "sr" -> Sr
    "sv" -> Sv
    "ta" -> Ta
    "te" -> Te
    "tl" -> Tl
    "th" -> Th
    "tk" -> Tk
    "tr" -> Tr
    "uk" -> Uk
    "ur" -> Ur
    "uz" -> Uz
    "vi" -> Vi
    "yi" -> Yi
    "zh" -> Zh
    "zu" -> Zu
    "afr" -> Afr
    "aka" -> Aka
    "amh" -> Amh
    "ara" -> Ara
    "aze" -> Aze
    "bel" -> Bel
    "ben" -> Ben
    "bul" -> Bul
    "cat" -> Cat
    "ces" -> Ces
    "dan" -> Dan
    "deu" -> Deu
    "ell" -> Ell
    "eng" -> Eng
    "epo" -> Epo
    "est" -> Est
    "fin" -> Fin
    "fra" -> Fra
    "guj" -> Guj
    "heb" -> Heb
    "hin" -> Hin
    "hrv" -> Hrv
    "hun" -> Hun
    "hye" -> Hye
    "ind" -> Ind
    "ita" -> Ita
    "jav" -> Jav
    "jpn" -> Jpn
    "kan" -> Kan
    "kat" -> Kat
    "khm" -> Khm
    "kor" -> Kor
    "lat" -> Lat
    "lav" -> Lav
    "lit" -> Lit
    "mal" -> Mal
    "mar" -> Mar
    "mkd" -> Mkd
    "mya" -> Mya
    "nep" -> Nep
    "nld" -> Nld
    "nob" -> Nob
    "ori" -> Ori
    "pan" -> Pan
    "pes" -> Pes
    "pol" -> Pol
    "por" -> Por
    "ron" -> Ron
    "rus" -> Rus
    "sin" -> Sin
    "slk" -> Slk
    "slv" -> Slv
    "sna" -> Sna
    "spa" -> Spa
    "srp" -> Srp
    "swe" -> Swe
    "tam" -> Tam
    "tel" -> Tel
    "tgl" -> Tgl
    "tha" -> Tha
    "tuk" -> Tuk
    "tur" -> Tur
    "ukr" -> Ukr
    "urd" -> Urd
    "uzb" -> Uzb
    "vie" -> Vie
    "yid" -> Yid
    "zho" -> Zho
    "zul" -> Zul
    "cmn" -> Cmn
    _ -> UnexpectedLocal
  }
}
