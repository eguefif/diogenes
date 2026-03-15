import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  MeilisearchSingleResult, UnexpectedHttpStatusCodeError,
  meilisearch_error_from_json, meilisearch_results_from_json, task_from_json,
}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/json
import gleam/option
import gleam/string
import internal/http_tooling.{create_base_request}

/// Adds a list of documents to an index, replacing any existing documents with the same primary key
///
/// - index_uid: unique identifier of the target index
/// - documents: list of documents to add
/// - encoder: function to encode each document into JSON
///
/// This is an asynchronous operation that returns a task object for progress tracking.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/add-or-replace-documents)
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

/// Retrieves a paginated list of documents from an index using query parameters
///
/// - index_uid: unique identifier of the target index
/// - parameters: pagination and filtering options (offset, limit, fields, filter, sort, ids, retrieve_vectors)
/// - decoder: function to decode each document from JSON
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/list-documents-with-get)
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
    |> request.set_header("Content-Type", "application/json")
    |> request.set_query(build_documents_query_params(parameters))

  #(request, fn(status: Int, body: String) {
    case status {
      200 -> meilisearch_results_from_json(body, decoder)
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  })
}

/// Retrieves a paginated list of documents from an index using a request body
///
/// - index_uid: unique identifier of the target index
/// - parameters: pagination and filtering options (offset, limit, fields, filter, sort, ids, retrieve_vectors)
/// - decoder: function to decode each document from JSON
///
/// Prefer this over `list_documents_with_get` when using complex filters.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/list-documents-with-post)
pub fn list_documents_with_post(
  client: Client,
  index_uid: String,
  parameters: ListDocumentsParams,
  decoder: decode.Decoder(document_type),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(document_type), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/documents/fetch")
    |> request.set_method(http.Post)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_query(build_documents_query_params(parameters))
    |> request.set_body(documents_params_to_json(parameters))

  let parser = fn(status: Int, body: String) {
    case status {
      200 -> meilisearch_results_from_json(body, decoder)
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

fn documents_params_to_json(parameters: ListDocumentsParams) -> String {
  let object =
    json.object([
      #("offset", json.int(parameters.offset)),
      #("limit", json.int(parameters.limit)),
      #("fields", case parameters.fields {
        None -> json.null()
        All -> json.string("*")
        Ids(ids) -> json.array(ids, json.string)
      }),
      #("retrieveVectors", json.bool(parameters.retrieve_vectors)),
      #("ids", case parameters.ids {
        option.Some(ids) -> json.array(ids, json.string)
        option.None -> json.null()
      }),
      #("filter", json.string(parameters.filter)),
      #("sort", case parameters.sort {
        [] -> json.null()
        _ -> json.array(parameters.sort, json.string)
      }),
    ])

  json.to_string(object)
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
    [] -> params
    _ -> [#("sort", string.join(sort, ",")), ..params]
  }
  let params = case ids {
    option.None -> params
    option.Some(ids) -> [#("ids", string.join(ids, ",")), ..params]
  }
  case fields {
    None -> params
    All -> [#("fields", "*"), ..params]
    Ids(ids) -> [#("fields", string.join(ids, ",")), ..params]
  }
}

/// Query parameters for list documents request
pub type ListDocumentsParams {
  ListDocumentsParams(
    offset: Int,
    limit: Int,
    fields: FieldsParam,
    retrieve_vectors: Bool,
    ids: option.Option(List(String)),
    filter: String,
    sort: List(String),
  )
}

/// Provides types for list_document_with_XXX functions
///
/// Fields are equivalent to dict keys, or SQL columns in Meilisearch's document.
pub type FieldsParam {
  None
  All
  Ids(List(String))
}

/// Permanently deletes all documents from an index while preserving its settings and metadata
///
/// - index_uid: unique identifier of the target index
///
/// This is an asynchronous operation that returns a task object for progress tracking.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/delete-all-documents)
pub fn delete_all_documents(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/documents")
    |> request.set_method(http.Delete)
  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Deletes a single document from an index using its primary key
///
/// - index_uid: unique identifier of the target index
/// - primary_key: identifier of the document to delete
///
/// This is an asynchronous operation that returns a task object for progress tracking.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/delete-document)
pub fn delete_document(
  client: Client,
  index_uid: String,
  primary_key: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/documents/" <> primary_key,
    )
    |> request.set_method(http.Delete)
  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Retrieves a single document from an index using its primary key
///
/// - index_uid: unique identifier of the target index
/// - document_id: primary key value of the document to retrieve
/// - query_params: optional fields selection and vector retrieval options
/// - decoder: function to decode the document from JSON
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/get-document)
pub fn get_document(
  client: Client,
  index_uid: String,
  document_id: String,
  query_params: GetDocumentParams,
  decoder: decode.Decoder(document_type),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(document_type), Error),
) {
  let request =
    create_base_request(
      client,
      "/indexes/" <> index_uid <> "/documents/" <> document_id,
    )
    |> request.set_method(http.Get)
    |> request.set_query(get_document_params_to_query(query_params))
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decoder) {
          Ok(document) -> Ok(MeilisearchSingleResult(result: document))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }

  #(request, parser)
}

/// Query parameters for the get_document function
pub type GetDocumentParams {
  GetDocumentParams(fields: FieldsParam, retrieve_vectors: Bool)
}

pub fn get_document_params_to_query(
  params: GetDocumentParams,
) -> List(#(String, String)) {
  let query = case params.fields {
    None -> []
    All -> [#("fields", "*")]
    Ids(ids) -> [#("fields", string.join(ids, ","))]
  }
  let query = [
    #("retrieveVectors", case params.retrieve_vectors {
      True -> "true"
      False -> "false"
    }),
    ..query
  ]
  query
}
