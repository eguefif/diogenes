//// Functions for managing Meilisearch tasks.
////
//// All write operations in Meilisearch (index creation, document updates,
//// settings changes, etc.) are asynchronous and return a task. Use these
//// functions to list, get, cancel, and delete tasks.
////
//// ## TODO
////
//// - [ ] Get all tasks - `GET /tasks`
//// - [ ] Get a task - `GET /tasks/{taskUid}`
//// - [ ] Cancel tasks - `POST /tasks/cancel`
//// - [ ] Delete tasks - `DELETE /tasks`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Retrieves a paginated list of all tasks, with optional filters.
///
/// Tasks are returned in descending order of uid (most recent first).
/// Supports filtering by status, type, index uid, and date ranges.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/tasks)
pub fn get_all_tasks(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Retrieves a single task by its uid.
///
/// - task_uid: unique identifier of the task
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/tasks)
pub fn get_task(
  client: Client,
  task_uid: Int,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = task_uid
  let _ = send_request
  todo
}

/// Cancels enqueued or processing tasks matching the given filters.
///
/// At least one filter must be provided. Canceled tasks will have their
/// status set to `canceled`.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/tasks)
pub fn cancel_tasks(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Permanently deletes finished tasks (succeeded, failed, or canceled) matching
/// the given filters.
///
/// At least one filter must be provided. Only finished tasks can be deleted.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/tasks)
pub fn delete_tasks(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}
