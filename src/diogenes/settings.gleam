//// Functions for managing Meilisearch index settings.
////
//// Settings control how an index searches, ranks, and tokenizes documents.
//// All write operations are asynchronous and return a task.
////
//// ## TODO
////
//// - [x] All settings - `/indexes/{indexUid}/settings`
//// - [x] Displayed attributes - `/indexes/{indexUid}/settings/displayed-attributes`
//// - [x] Searchable attributes - `/indexes/{indexUid}/settings/searchable-attributes`
//// - [x] Filterable attributes - `/indexes/{indexUid}/settings/filterable-attributes`
//// - [x] Sortable attributes - `/indexes/{indexUid}/settings/sortable-attributes`
//// - [ ] Ranking rules - `/indexes/{indexUid}/settings/ranking-rules`
//// - [x] Stop words - `/indexes/{indexUid}/settings/stop-words`
//// - [ ] Synonyms - `/indexes/{indexUid}/settings/synonyms`
//// - [ ] Distinct attribute - `/indexes/{indexUid}/settings/distinct-attribute`
//// - [ ] Typo tolerance - `/indexes/{indexUid}/settings/typo-tolerance`
//// - [ ] Faceting - `/indexes/{indexUid}/settings/faceting`
//// - [ ] Pagination - `/indexes/{indexUid}/settings/pagination`
//// - [x] Dictionary - `/indexes/{indexUid}/settings/dictionary`
//// - [x] Separator tokens - `/indexes/{indexUid}/settings/separator-tokens`
//// - [x] Non-separator tokens - `/indexes/{indexUid}/settings/non-separator-tokens`
//// - [ ] Localized attributes - `/indexes/{indexUid}/settings/localized-attributes`
//// - [ ] Embedders - `/indexes/{indexUid}/settings/embedders`
//// - [ ] Proximity precision - `/indexes/{indexUid}/settings/proximity-precision`
//// - [ ] Search cutoff ms - `/indexes/{indexUid}/settings/search-cutoff-ms`
//// - [ ] Facet search - `/indexes/{indexUid}/settings/facet-search`
//// - [ ] Prefix search - `/indexes/{indexUid}/settings/prefix-search`
//// - [x] Chat - `/indexes/{indexUid}/settings/chat`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import diogenes/sansio/settings as sansio_settings
import internal/http_tooling.{send_request}

/// Resets all settings for the given index to their default values.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_all_settings(client, "movies")
/// ```
pub fn reset_all_settings(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) = sansio_settings.reset_all_settings(client, index_uid)
  send_request(request, [401, 404], parser)
}

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

/// Retrieves the displayed attributes setting for the given index.
///
/// Displayed attributes are the fields returned in search results.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(attributes)) =
///   get_displayed_attributes(client, "movies")
/// ```
pub fn get_displayed_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_displayed_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the displayed attributes setting for the given index.
///
/// Displayed attributes are the fields returned in search results.
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_displayed_attributes(client, "movies", ["title", "overview"])
/// ```
pub fn update_displayed_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_displayed_attributes(client, index_uid, attributes)
  send_request(request, [401, 404], parser)
}

/// Resets the displayed attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_displayed_attributes(client, "movies")
/// ```
pub fn reset_displayed_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_displayed_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the searchable attributes setting for the given index.
///
/// Searchable attributes are the fields Meilisearch searches through when
/// processing a query.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(attributes)) =
///   get_searchable_attributes(client, "movies")
/// ```
pub fn get_searchable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_searchable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the searchable attributes setting for the given index.
///
/// Searchable attributes are the fields Meilisearch searches through when
/// processing a query. The operation is asynchronous — Meilisearch enqueues it
/// and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_searchable_attributes(client, "movies", ["title", "overview"])
/// ```
pub fn update_searchable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_searchable_attributes(client, index_uid, attributes)
  send_request(request, [401, 404], parser)
}

/// Resets the searchable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_searchable_attributes(client, "movies")
/// ```
pub fn reset_searchable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_searchable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the sortable attributes setting for the given index.
///
/// Sortable attributes are the fields that can be used to sort search results.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(attributes)) =
///   get_sortable_attributes(client, "movies")
/// ```
pub fn get_sortable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_sortable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the sortable attributes setting for the given index.
///
/// Sortable attributes are the fields that can be used to sort search results.
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_sortable_attributes(client, "movies", ["release_date", "title"])
/// ```
pub fn update_sortable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_sortable_attributes(client, index_uid, attributes)
  send_request(request, [401, 404], parser)
}

/// Resets the sortable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_sortable_attributes(client, "movies")
/// ```
pub fn reset_sortable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_sortable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the non-separator tokens setting for the given index.
///
/// Non-separator tokens are characters that Meilisearch should not treat as
/// word separators during tokenization.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(tokens)) =
///   get_non_separator_tokens(client, "movies")
/// ```
pub fn get_non_separator_tokens(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_non_separator_tokens(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the non-separator tokens setting for the given index.
///
/// Non-separator tokens are characters that Meilisearch should not treat as
/// word separators during tokenization. The operation is asynchronous —
/// Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_non_separator_tokens(client, "movies", ["@", "#"])
/// ```
pub fn update_non_separator_tokens(
  client: Client,
  index_uid: String,
  tokens: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_non_separator_tokens(client, index_uid, tokens)
  send_request(request, [401, 404], parser)
}

/// Resets the non-separator tokens setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_non_separator_tokens(client, "movies")
/// ```
pub fn reset_non_separator_tokens(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_non_separator_tokens(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the separator tokens setting for the given index.
///
/// Separator tokens are characters that Meilisearch treats as word separators
/// during tokenization.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(tokens)) =
///   get_separator_tokens(client, "movies")
/// ```
pub fn get_separator_tokens(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_separator_tokens(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the separator tokens setting for the given index.
///
/// Separator tokens are characters that Meilisearch treats as word separators
/// during tokenization. The operation is asynchronous — Meilisearch enqueues
/// it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_separator_tokens(client, "movies", ["|", "/"])
/// ```
pub fn update_separator_tokens(
  client: Client,
  index_uid: String,
  tokens: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_separator_tokens(client, index_uid, tokens)
  send_request(request, [401, 404], parser)
}

/// Resets the separator tokens setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_separator_tokens(client, "movies")
/// ```
pub fn reset_separator_tokens(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_separator_tokens(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the stop words setting for the given index.
///
/// Stop words are words ignored by Meilisearch during search (e.g. "the", "a").
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(words)) =
///   get_stop_words(client, "movies")
/// ```
pub fn get_stop_words(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) = sansio_settings.get_stop_words(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the stop words setting for the given index.
///
/// Stop words are words ignored by Meilisearch during search (e.g. "the", "a").
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_stop_words(client, "movies", ["the", "a", "an"])
/// ```
pub fn update_stop_words(
  client: Client,
  index_uid: String,
  words: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_stop_words(client, index_uid, words)
  send_request(request, [401, 404], parser)
}

/// Resets the stop words setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_stop_words(client, "movies")
/// ```
pub fn reset_stop_words(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_stop_words(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Retrieves the filterable attributes setting for the given index.
///
/// Filterable attributes are the fields that can be used in filter expressions
/// during search.
///
/// On success returns `Ok(MeilisearchSingleResult(List(String)))`.
/// Errors include `MeilisearchError` for 401/404 responses and
/// `TransportError` for network failures.
///
/// ## Example
/// ```gleam
/// let assert Ok(MeilisearchSingleResult(attributes)) =
///   get_filterable_attributes(client, "movies")
/// ```
pub fn get_filterable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(List(String)), Error) {
  let #(request, parser) =
    sansio_settings.get_filterable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}

/// Updates the filterable attributes setting for the given index.
///
/// Filterable attributes are the fields that can be used in filter expressions
/// during search. The operation is asynchronous — Meilisearch enqueues it and
/// returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   update_filterable_attributes(client, "movies", ["genre", "year"])
/// ```
pub fn update_filterable_attributes(
  client: Client,
  index_uid: String,
  attributes: List(String),
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.update_filterable_attributes(client, index_uid, attributes)
  send_request(request, [401, 404], parser)
}

/// Resets the filterable attributes setting for the given index to its default value.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a `Task`.
///
/// On success returns `Ok(Task(...))`.
///
/// ## Example
/// ```gleam
/// let assert Ok(Task(task_uid: uid, ..)) =
///   reset_filterable_attributes(client, "movies")
/// ```
pub fn reset_filterable_attributes(
  client: Client,
  index_uid: String,
) -> Result(MeilisearchResponse(task), Error) {
  let #(request, parser) =
    sansio_settings.reset_filterable_attributes(client, index_uid)
  send_request(request, [401, 404], parser)
}
