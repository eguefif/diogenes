//// Functions for managing Meilisearch index settings.
////
//// Settings control how an index searches, ranks, and tokenizes documents.
//// All write operations are asynchronous and return a task.
////
//// ## TODO
////
//// - [x] Get all settings - `GET /indexes/{indexUid}/settings`
//// - [x] Update settings - `PATCH /indexes/{indexUid}/settings`
//// - [ ] Reset settings - `DELETE /indexes/{indexUid}/settings`
//// - [ ] Get displayed attributes - `GET /indexes/{indexUid}/settings/displayed-attributes`
//// - [ ] Update displayed attributes - `PUT /indexes/{indexUid}/settings/displayed-attributes`
//// - [ ] Reset displayed attributes - `DELETE /indexes/{indexUid}/settings/displayed-attributes`
//// - [ ] Get searchable attributes - `GET /indexes/{indexUid}/settings/searchable-attributes`
//// - [ ] Update searchable attributes - `PUT /indexes/{indexUid}/settings/searchable-attributes`
//// - [ ] Reset searchable attributes - `DELETE /indexes/{indexUid}/settings/searchable-attributes`
//// - [ ] Get filterable attributes - `GET /indexes/{indexUid}/settings/filterable-attributes`
//// - [ ] Update filterable attributes - `PUT /indexes/{indexUid}/settings/filterable-attributes`
//// - [ ] Reset filterable attributes - `DELETE /indexes/{indexUid}/settings/filterable-attributes`
//// - [ ] Get sortable attributes - `GET /indexes/{indexUid}/settings/sortable-attributes`
//// - [ ] Update sortable attributes - `PUT /indexes/{indexUid}/settings/sortable-attributes`
//// - [ ] Reset sortable attributes - `DELETE /indexes/{indexUid}/settings/sortable-attributes`
//// - [ ] Get ranking rules - `GET /indexes/{indexUid}/settings/ranking-rules`
//// - [ ] Update ranking rules - `PUT /indexes/{indexUid}/settings/ranking-rules`
//// - [ ] Reset ranking rules - `DELETE /indexes/{indexUid}/settings/ranking-rules`
//// - [ ] Get stop words - `GET /indexes/{indexUid}/settings/stop-words`
//// - [ ] Update stop words - `PUT /indexes/{indexUid}/settings/stop-words`
//// - [ ] Reset stop words - `DELETE /indexes/{indexUid}/settings/stop-words`
//// - [ ] Get synonyms - `GET /indexes/{indexUid}/settings/synonyms`
//// - [ ] Update synonyms - `PUT /indexes/{indexUid}/settings/synonyms`
//// - [ ] Reset synonyms - `DELETE /indexes/{indexUid}/settings/synonyms`
//// - [ ] Get distinct attribute - `GET /indexes/{indexUid}/settings/distinct-attribute`
//// - [ ] Update distinct attribute - `PUT /indexes/{indexUid}/settings/distinct-attribute`
//// - [ ] Reset distinct attribute - `DELETE /indexes/{indexUid}/settings/distinct-attribute`
//// - [ ] Get typo tolerance - `GET /indexes/{indexUid}/settings/typo-tolerance`
//// - [ ] Update typo tolerance - `PATCH /indexes/{indexUid}/settings/typo-tolerance`
//// - [ ] Reset typo tolerance - `DELETE /indexes/{indexUid}/settings/typo-tolerance`
//// - [ ] Get faceting - `GET /indexes/{indexUid}/settings/faceting`
//// - [ ] Update faceting - `PATCH /indexes/{indexUid}/settings/faceting`
//// - [ ] Reset faceting - `DELETE /indexes/{indexUid}/settings/faceting`
//// - [ ] Get pagination - `GET /indexes/{indexUid}/settings/pagination`
//// - [ ] Update pagination - `PATCH /indexes/{indexUid}/settings/pagination`
//// - [ ] Reset pagination - `DELETE /indexes/{indexUid}/settings/pagination`
//// - [ ] Get dictionary - `GET /indexes/{indexUid}/settings/dictionary`
//// - [ ] Update dictionary - `PUT /indexes/{indexUid}/settings/dictionary`
//// - [ ] Reset dictionary - `DELETE /indexes/{indexUid}/settings/dictionary`
//// - [ ] Get separator tokens - `GET /indexes/{indexUid}/settings/separator-tokens`
//// - [ ] Update separator tokens - `PUT /indexes/{indexUid}/settings/separator-tokens`
//// - [ ] Reset separator tokens - `DELETE /indexes/{indexUid}/settings/separator-tokens`
//// - [ ] Get non-separator tokens - `GET /indexes/{indexUid}/settings/non-separator-tokens`
//// - [ ] Update non-separator tokens - `PUT /indexes/{indexUid}/settings/non-separator-tokens`
//// - [ ] Reset non-separator tokens - `DELETE /indexes/{indexUid}/settings/non-separator-tokens`
//// - [ ] Get localized attributes - `GET /indexes/{indexUid}/settings/localized-attributes`
//// - [ ] Update localized attributes - `PUT /indexes/{indexUid}/settings/localized-attributes`
//// - [ ] Reset localized attributes - `DELETE /indexes/{indexUid}/settings/localized-attributes`
//// - [ ] Get embedders - `GET /indexes/{indexUid}/settings/embedders`
//// - [ ] Update embedders - `PATCH /indexes/{indexUid}/settings/embedders`
//// - [ ] Reset embedders - `DELETE /indexes/{indexUid}/settings/embedders`
//// - [ ] Get proximity precision - `GET /indexes/{indexUid}/settings/proximity-precision`
//// - [ ] Update proximity precision - `PUT /indexes/{indexUid}/settings/proximity-precision`
//// - [ ] Reset proximity precision - `DELETE /indexes/{indexUid}/settings/proximity-precision`
//// - [ ] Get search cutoff ms - `GET /indexes/{indexUid}/settings/search-cutoff-ms`
//// - [ ] Update search cutoff ms - `PUT /indexes/{indexUid}/settings/search-cutoff-ms`
//// - [ ] Reset search cutoff ms - `DELETE /indexes/{indexUid}/settings/search-cutoff-ms`
//// - [ ] Get facet search setting - `GET /indexes/{indexUid}/settings/facet-search`
//// - [ ] Update facet search setting - `PUT /indexes/{indexUid}/settings/facet-search`
//// - [ ] Reset facet search setting - `DELETE /indexes/{indexUid}/settings/facet-search`
//// - [ ] Get prefix search - `GET /indexes/{indexUid}/settings/prefix-search`
//// - [ ] Update prefix search - `PUT /indexes/{indexUid}/settings/prefix-search`
//// - [ ] Reset prefix search - `DELETE /indexes/{indexUid}/settings/prefix-search`
//// - [ ] Get chat settings - `GET /indexes/{indexUid}/settings/chat`
//// - [ ] Update chat settings - `PUT /indexes/{indexUid}/settings/chat`
//// - [ ] Reset chat settings - `DELETE /indexes/{indexUid}/settings/chat`

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

/// Retrieves the chat settings for the given index.
///
/// On success returns `Ok(MeilisearchSingleResult(Chat))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(chat)) =
///   get_chat(client, "movies")
/// ```
pub fn get_chat(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(sansio_settings.Chat), Error) {
  let #(request, parser) = sansio_settings.get_chat(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the chat settings for the given index.
///
/// Configures how the index is presented to the LLM, including the description,
/// document template, and search parameters. The operation is asynchronous —
/// Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_chat(client, "movies", chat_settings)
/// ```
pub fn update_chat(
  client: Client,
  index_uid: String,
  chat_settings: sansio_settings.Chat,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_chat(client, index_uid, chat_settings)
  send_request(request, [401, 404], parser)
}

/// Resets the chat settings for the given index to their default values.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_chat(client, "movies")
/// ```
pub fn reset_chat(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) = sansio_settings.reset_chat(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the dictionary setting for the given index.
///
/// The dictionary is a list of custom words treated as distinct tokens
/// during tokenization.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(words)) =
///   get_dictionary(client, "movies")
/// ```
pub fn get_dictionary(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) = sansio_settings.get_dictionary(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the dictionary setting for the given index.
///
/// The dictionary is a list of custom words that Meilisearch treats as
/// distinct tokens during tokenization (e.g. `["J. R. R.", "W. E. B."]`).
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_dictionary(client, "movies", ["J. R. R."])
/// ```
pub fn update_dictionary(
  client: Client,
  index_uid: String,
  dictionnary: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_dictionary(client, index_uid, dictionnary)
  send_request(request, [401, 404], parser)
}

/// Resets the dictionary setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_dictionary(client, "movies")
/// ```
pub fn reset_dictionary(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) = sansio_settings.reset_dictionary(client, index_uid)
  send_request(request, [401, 404], parser)
}
