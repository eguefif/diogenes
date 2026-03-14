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
import gleam/option.{type Option}
import internals/http_tooling.{create_base_request}

pub type Index {
  IndexCreation(uid: String, primary_key: Option(String))
  Index(
    uid: String,
    primary_key: Option(String),
    created_at: String,
    updated_at: String,
  )
}

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
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body =
    json.to_string(index_creation_to_json(IndexCreation(uid:, primary_key:)))

  let request =
    create_base_request(client, "/indexes")
    |> request.set_body(body)
    |> request.set_method(http.Post)

  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(JsonError(err))
        }
      401 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError)
    }
  }
  #(request, parser)
}

fn index_creation_to_json(idx: Index) -> json.Json {
  let assert IndexCreation(..) = idx
  json.object([
    #("uid", json.string(idx.uid)),
    #("primaryKey", case idx.primary_key {
      option.Some(pk) -> json.string(pk)
      option.None -> json.null()
    }),
  ])
}

//fn index_creation_from_json(
//  json_string: String,
//) -> Result(Index, json.DecodeError) {
//  let decoder = {
//    use uid <- decode.field("uid", decode.string)
//    use primary_key <- decode.field(
//      "primaryKey",
//      decode.optional(decode.string),
//    )
//    decode.success(IndexCreation(uid:, primary_key:))
//  }
//  json.parse(from: json_string, using: decoder)
//}

pub fn list_index(
  client: Client,
  offset: Option(Int),
  limit: Option(Int),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Index), Error),
) {
  let request =
    create_base_request(client, "/indexes")
    |> request.set_method(http.Get)
    |> request.set_query([
      #("offset", int.to_string(option.unwrap(offset, 0))),
      #("limit", int.to_string(option.unwrap(limit, 20))),
    ])

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case list_index_from_json(body) {
          Ok(indexes) -> Ok(indexes)
          Error(error) -> Error(error)
        }
      401 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError)
    }
  }
  #(request, parser)
}

fn list_index_from_json(
  body: String,
) -> Result(MeilisearchResponse(Index), Error) {
  let index_decoder = {
    use uid <- decode.field("uid", decode.string)
    use primary_key <- decode.field(
      "primaryKey",
      decode.optional(decode.string),
    )
    use created_at <- decode.field("createdAt", decode.string)
    use updated_at <- decode.field("updatedAt", decode.string)

    decode.success(Index(uid:, primary_key:, created_at:, updated_at:))
  }
  meilisearch_results_from_json(body, index_decoder)
}
