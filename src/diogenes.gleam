//// Gleam Meilisearch client
//// This module contains the mains type and the client factory.
////
//// The client is a type that contains url and api_key that are used to create Request
//// 
//// ## Example
//// ```
//// let client = diogenes.new_client("http://127.0.0.1:7000", None)
//// 
//// let _ = health.get_health(client)
//// 
//// ```

import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/uri

/// Returns a client to be used anytime we build request.
///
/// It expects an url such as http://127.0.0.1:7000
/// ```
///    let client = new_client("http://127.0.0.1:7000", None)
///    diogenes.health(client)
///```
pub fn new_client(url: String, api_key: Option(String)) -> Client {
  let assert Ok(uri) = uri.parse(url)
  Client(uri:, api_key:)
}

pub type Client {
  Client(uri: uri.Uri, api_key: Option(String))
}

pub type Error {
  Uri
  TransportError(httpc.HttpError)
  ResponseError(status: Int, body: String)
  MeilisearchError(message: String, code: String, type_: String, link: String)
  JsonError(json.DecodeError)
  UnexpectedHttpStatusCodeError(status: Int, body: String)
}

pub type MeilisearchResponse(result_type) {
  Task(
    task_uid: Int,
    index_uid: String,
    status: TaskStatus,
    type_: TaskType,
    enqueued_at: String,
    custom_metadata: Option(String),
  )
  MeilisearchResults(
    results: List(result_type),
    limit: Int,
    offset: Int,
    total: Int,
  )
  MeilisearchSingleResult(result: result_type)
  Empty
}

pub fn meilisearch_results_from_json(
  results_string: String,
  item_decoder: decode.Decoder(result_type),
) -> Result(MeilisearchResponse(result_type), Error) {
  let decoder = {
    use results <- decode.field("results", decode.list(item_decoder))
    use limit <- decode.field("limit", decode.int)
    use offset <- decode.field("offset", decode.int)
    use total <- decode.field("total", decode.int)
    decode.success(MeilisearchResults(results:, limit:, offset:, total:))
  }
  json.parse(results_string, decoder)
  |> result.map_error(fn(error) { JsonError(error) })
}

pub fn meilisearch_error_from_json(error_string: String) -> Error {
  let decoder = {
    use message <- decode.field("message", decode.string)
    use code <- decode.field("code", decode.string)
    use type_ <- decode.field("type", decode.string)
    use link <- decode.field("link", decode.string)

    decode.success(MeilisearchError(message:, code:, type_:, link:))
  }
  case json.parse(error_string, decoder) {
    Ok(error) -> error
    Error(error) -> JsonError(error)
  }
}

pub type TaskStatus {
  Enqueued
  Processing
  Succeeded
  Failed
  Canceled
}

pub type TaskType {
  DocumentAdditionOrUpdate
  DocumentEdition
  DocumentDeletion
  SettingsUpdate
  IndexCreation
  IndexDeletion
  IndexUpdate
  IndexSwap
  TaskCancelation
  TaskDeletion
  DumpCreation
  SnapshotCreation
  Export
  UpgradeDatabase
  IndexCompaction
  NetworkTopologyChange
}

pub fn task_to_json(task: MeilisearchResponse(a)) -> json.Json {
  let assert Task(..) = task
  let object_task = [
    #("taskUid", json.int(task.task_uid)),
    #("indexUid", json.string(task.index_uid)),
    #("status", task_status_to_json(task.status)),
    #("type", task_type_to_json(task.type_)),
    #("enqueuedAt", json.string(task.enqueued_at)),
  ]
  case task.custom_metadata {
    option.Some(metadata) ->
      json.object([#("customMetadata", json.string(metadata)), ..object_task])
    option.None -> json.object(object_task)
  }
}

pub fn task_from_json(
  task_string: String,
) -> Result(MeilisearchResponse(a), json.DecodeError) {
  let decoder = {
    use task_uid <- decode.field("taskUid", decode.int)
    use index_uid <- decode.field("indexUid", decode.string)
    use status <- decode.field(
      "status",
      decode.string |> decode.map(fn(v) { task_status_map(v) }),
    )
    use type_ <- decode.field(
      "type",
      decode.string |> decode.map(fn(v) { task_type_map(v) }),
    )
    use enqueued_at <- decode.field("enqueuedAt", decode.string)
    use custom_metadata <- decode.optional_field(
      "customMetadata",
      option.None,
      decode.optional(decode.string),
    )

    decode.success(Task(
      task_uid:,
      index_uid:,
      status:,
      type_:,
      enqueued_at:,
      custom_metadata:,
    ))
  }
  json.parse(task_string, decoder)
}

fn task_type_map(task_type: String) -> TaskType {
  case task_type {
    "documentAdditionOrUpdate" -> DocumentAdditionOrUpdate
    "documentEdition" -> DocumentEdition
    "documentDeletion" -> DocumentDeletion
    "settingsUpdate" -> SettingsUpdate
    "indexCreation" -> IndexCreation
    "indexDeletion" -> IndexDeletion
    "indexUpdate" -> IndexUpdate
    "indexSwap" -> IndexSwap
    "taskCancelation" -> TaskCancelation
    "taskDeletion" -> TaskDeletion
    "dumpCreation" -> DumpCreation
    "snapshotCreation" -> SnapshotCreation
    "export" -> Export
    "updateDatabase" -> UpgradeDatabase
    "indexCompaction" -> IndexCompaction
    "networkTopologyChange" -> NetworkTopologyChange
    _ -> panic
  }
}

fn task_status_map(status: String) -> TaskStatus {
  case status {
    "enqueued" -> Enqueued
    "processing" -> Processing
    "succeeded" -> Succeeded
    "failed" -> Failed
    "canceled" -> Canceled
    _ -> panic
  }
}

fn task_type_to_json(type_: TaskType) -> json.Json {
  case type_ {
    DocumentAdditionOrUpdate -> json.string("documentAdditionOrUpdate")
    DocumentEdition -> json.string("documentEdition")
    DocumentDeletion -> json.string("documentDeletion")
    SettingsUpdate -> json.string("settingsUpdate")
    IndexCreation -> json.string("indexCreation")
    IndexDeletion -> json.string("indexDeletion")
    IndexUpdate -> json.string("indexUpdate")
    IndexSwap -> json.string("indexSwap")
    TaskCancelation -> json.string("taskCancelation")
    TaskDeletion -> json.string("taskDeletion")
    DumpCreation -> json.string("dumpCreation")
    SnapshotCreation -> json.string("snapshotCreation")
    Export -> json.string("export")
    UpgradeDatabase -> json.string("upgradeDatabase")
    IndexCompaction -> json.string("indexCompaction")
    NetworkTopologyChange -> json.string("networkTopologyChange")
  }
}

pub fn task_status_to_json(status: TaskStatus) -> json.Json {
  case status {
    Enqueued -> json.string("enqueued")
    Processing -> json.string("processing")
    Succeeded -> json.string("succeeded")
    Failed -> json.string("failed")
    Canceled -> json.string("canceled")
  }
}
