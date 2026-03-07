//// Typing

import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{type Option}
import gleam/uri

pub type Client {
  Client(uri: uri.Uri, api_key: Option(String))
}

pub type Error {
  Uri
  ResponseError(String)
  JsonError(String)
}

pub type Task {
  Task(
    task_uid: Int,
    index_uid: String,
    status: TaskStatus,
    type_: TaskType,
    enqueued_at: String,
    custom_metadata: Option(String),
  )
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

pub fn task_to_json(task: Task) -> json.Json {
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

pub fn task_from_json(task_string: String) -> Result(Task, json.DecodeError) {
  io.println("Task string: " <> task_string)
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
