import diogenes/http_tooling.{create_base_request}
import diogenes/types.{task_from_json}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option}
import gleam/string

type Index {
  IndexCreation(uid: String, primary_key: Option(String))
}

fn indexcreation_to_json(idx: Index) -> json.Json {
  json.object([
    #("uid", json.string(idx.uid)),
    #("primaryKey", case idx.primary_key {
      option.Some(pk) -> json.string(pk)
      option.None -> json.null()
    }),
  ])
}

fn indexcreation_from_json(
  json_string: String,
) -> Result(Index, json.DecodeError) {
  let decoder = {
    use uid <- decode.field("uid", decode.string)
    use primary_key <- decode.field(
      "primaryKey",
      decode.optional(decode.string),
    )
    decode.success(IndexCreation(uid:, primary_key:))
  }
  json.parse(from: json_string, using: decoder)
}

pub fn create_index(
  client: types.Client,
  uid: String,
  primary_key: Option(String),
) -> #(Request(String), fn(Response(String)) -> Result(types.Task, types.Error)) {
  let body =
    json.to_string(indexcreation_to_json(IndexCreation(uid:, primary_key:)))
  let request =
    create_base_request(client, "/indexes")
    |> request.set_body(body)
    |> request.set_method(http.Post)

  let parser = fn(response: Response(String)) {
    case response.status {
      202 ->
        case task_from_json(response.body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(types.JsonError(string.inspect(err)))
        }
      401 -> Error(types.ResponseError(response.body))
      _ -> panic
    }
  }
  #(request, parser)
}
