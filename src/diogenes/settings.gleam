import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/settings as sansio_settings
import internal/http_tooling.{send_request}

/// Retrieves all settings for the given index.
///
/// On success returns `Ok(MeilisearchSingleResult(Settings))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(settings)) =
///   list_all_settings(client, "movies")
/// ```
pub fn list_all_settings(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(sansio_settings.Settings), Error) {
  let #(request, parser) = sansio_settings.list_all_settings(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates settings for the given index.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a
/// `Task`. Poll the task endpoint to check completion.
/// Passing `null` for a field resets it to its default value.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_all_settings(client, "movies", settings)
/// ```
pub fn update_all_settings(
  client: Client,
  index_uid: String,
  settings: sansio_settings.Settings,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_all_settings(client, index_uid, settings)
  send_request(request, [401, 404], parser)
}
