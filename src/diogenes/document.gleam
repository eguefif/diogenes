import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/document as sansio_document
import gleam/dynamic/decode
import gleam/json
import gleam/option
import internals/http_tooling.{send_request}

// TODO: 
// - [x] list document with get
// - [x] list document with post
// - [x] add or create documents
// - [ ] add or update documents
// - [ ] Handle multi format to add or ... csv, ndjson
// - [ ] Add query paramter to add or ... documents functions
// - [x] get document
// - [x] delete document
// - [x] delete all documents
// - [ ] delete documents by filter
// - [ ] delete documents by batch
// - [ ] edit documents by function - Todo later

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
  query_params: sansio_document.GetDocumentParams,
  decoder: decode.Decoder(document_type),
) -> Result(MeilisearchResponse(document_type), Error) {
  let #(request, parser) =
    sansio_document.get_document(
      client,
      index_uid,
      document_id,
      query_params,
      decoder,
    )
  send_request(request, [401, 404], parser)
}

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
) -> Result(MeilisearchResponse(document_type), Error) {
  let #(request, parser) =
    sansio_document.add_or_replace_documents(
      client,
      index_uid,
      documents,
      encoder,
    )
  send_request(request, [401, 404], parser)
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
  parameters: sansio_document.ListDocumentsParams,
  decoder: decode.Decoder(document_type),
) -> Result(MeilisearchResponse(document_type), Error) {
  let #(request, parser) =
    sansio_document.list_documents_with_get(
      client,
      index_uid,
      parameters,
      decoder,
    )
  send_request(request, [401, 404], parser)
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
  parameters: sansio_document.ListDocumentsParams,
  decoder: decode.Decoder(document_type),
) -> Result(MeilisearchResponse(document_type), Error) {
  let #(request, parser) =
    sansio_document.list_documents_with_post(
      client,
      index_uid,
      parameters,
      decoder,
    )
  send_request(request, [401, 404], parser)
}

pub fn default_list_documents_params() -> sansio_document.ListDocumentsParams {
  sansio_document.ListDocumentsParams(
    0,
    20,
    sansio_document.None,
    False,
    option.None,
    "",
    [],
  )
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
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_document.delete_all_documents(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Deletes a single document from an index using its primary key
///
/// - index_id: unique identifier of the target index
/// - primary_key: identifier of the document to delete
///
/// This is an asynchronous operation that returns a task object for progress tracking.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/documents/delete-document)
pub fn delete_document(
  client: Client,
  index_uid: String,
  primary_key: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_document.delete_document(client, index_uid, primary_key)
  send_request(request, [401, 404], parser)
}
