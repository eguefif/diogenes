import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/document as sansio_document
import gleam/dynamic/decode
import gleam/json
import internals/http_tooling.{send_request}

// TODO: 
// - [ ] get document
// - [ ] list document with post
// - [ ] add or update documents
// - [ ] delete document
// - [ ] delete all documents
// - [ ] delete documents by filter
// - [ ] delete documents by batch
// - [ ] edit documents by function

/// This take a list of documents which are of the type you want.
///
/// The encoder will allow the diogenes to encode into json.
///
/// https://www.meilisearch.com/docs/reference/api/documents/add-or-replace-documents
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

/// Retrieves all documents with pagination
///
/// https://www.meilisearch.com/docs/reference/api/documents/list-documents-with-get
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

pub fn default_list_documents_params() -> sansio_document.ListDocumentsParams {
  sansio_document.ListDocumentsParams(0, 20, [], False, [], "", "")
}
