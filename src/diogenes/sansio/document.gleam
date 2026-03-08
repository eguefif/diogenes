import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  meilisearch_error_from_json, task_from_json,
}
import gleam/http
import gleam/http/request.{type Request}
import gleam/json
import internals/http_tooling.{create_base_request}

/// This take a list of documents which are of the type you want.
/// The encoder will allow the diogenes to encode into json.
/// https://www.meilisearch.com/docs/reference/api/documents/add-or-replace-documents
pub fn add_or_replace_documents(
  client: Client,
  index_uid: String,
  documents: List(document_type),
  encoder: fn(document_type) -> json.Json,
) -> #(Request(String), fn(Int, String) -> Result(MeilisearchResponse, Error)) {
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
      401 | 404 -> {
        case meilisearch_error_from_json(body) {
          Ok(error) -> Error(error)
          Error(error) -> Error(JsonError(error))
        }
      }
      _ -> panic
    }
  })
}
