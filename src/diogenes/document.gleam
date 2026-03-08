import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/document as sansio_document
import gleam/json
import internals/http_tooling.{send_request}

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
) -> Result(MeilisearchResponse, Error) {
  let #(request, parser) =
    sansio_document.add_or_replace_documents(
      client,
      index_uid,
      documents,
      encoder,
    )
  send_request(request, [], parser)
}
