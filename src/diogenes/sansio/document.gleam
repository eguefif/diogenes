import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  UnexpectedHttpStatusCodeError, meilisearch_error_from_json,
  meilisearch_results_from_json, task_from_json,
}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/json
import gleam/string
import internals/http_tooling.{create_base_request}

/// This take a list of documents which are of the type you want.
/// The encoder will allow the diogenes to encode into json.
/// https://www.meilisearch.com/docs/reference/api/documents/add-or-replace-documents
pub fn add_or_replace_documents(
  client: Client,
  index_uid: String,
  documents: List(document_type),
  encoder: fn(document_type) -> json.Json,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(document_type), Error),
) {
  let body = json.array(documents, encoder) |> json.to_string()
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/documents")
    |> request.set_method(http.Post)
    |> request.set_body(body)

  #(request, fn(status: Int, body: String) {
    case status {
      202 -> {
        case task_from_json(body) {
          Ok(response) -> Ok(response)
          Error(error) -> Error(JsonError(error))
        }
      }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  })
}

/// Retrieves all documents with pagination (sans-io)
///
/// https://www.meilisearch.com/docs/reference/api/documents/list-documents-with-get
pub fn list_documents_with_get(
  client: Client,
  index_uid: String,
  parameters: ListDocumentsParams,
  decoder: decode.Decoder(document_type),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(document_type), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/documents")
    |> request.set_method(http.Get)
    |> request.set_query(build_documents_query_params(parameters))

  #(request, fn(status: Int, body: String) {
    case status {
      200 -> meilisearch_results_from_json(body, decoder)
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  })
}

fn build_documents_query_params(
  parameters: ListDocumentsParams,
) -> List(#(String, String)) {
  let ListDocumentsParams(
    offset,
    limit,
    fields,
    retrieve_vectors,
    ids,
    filter,
    sort,
  ) = parameters

  let params = [
    #("offset", int.to_string(offset)),
    #("limit", int.to_string(limit)),
    #("retrieveVectors", case retrieve_vectors {
      True -> "true"
      False -> "false"
    }),
    #("filter", filter),
  ]

  let params = case sort {
    "" -> params
    _ -> [#("sort", sort), ..params]
  }
  let params = case ids {
    [] -> params
    _ -> [#("ids", string.join(ids, ",")), ..params]
  }
  case fields {
    [] -> params
    _ -> [
      #("fields", case fields {
        [] -> "*"
        _ -> string.join(fields, ",")
      }),
      ..params
    ]
  }
}

/// Query parameters for list documents request
///
/// If you want to retrieve all the fields, use an empty []
pub type ListDocumentsParams {
  ListDocumentsParams(
    offset: Int,
    limit: Int,
    fields: List(String),
    retrieve_vectors: Bool,
    ids: List(String),
    filter: String,
    sort: String,
  )
}
