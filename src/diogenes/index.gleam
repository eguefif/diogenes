import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/index as sansio_index
import gleam/option.{type Option}
import internals/http_tooling.{send_request}

/// Creates a Meilisearch index
///
/// - uid: unique index identifier
/// - primary_key: id from the document to references as a primary_key
///
/// https://www.meilisearch.com/docs/reference/api/indexes/create-index
pub fn create_index(
  client: Client,
  uid: String,
  primary_key: Option(String),
) -> Result(MeilisearchResponse, Error) {
  let #(request, parser) = sansio_index.create_index(client, uid, primary_key)
  send_request(request, [401], parser)
}
