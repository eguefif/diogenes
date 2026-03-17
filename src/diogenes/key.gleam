//// Functions for managing Meilisearch API keys.
////
//// API keys control access to Meilisearch endpoints. Each key has a set of
//// permitted actions and accessible indexes. The master key is required to
//// manage API keys.
////
//// ## TODO
////
//// - [ ] Get API keys - `GET /keys`
//// - [ ] Create API key - `POST /keys`
//// - [ ] Get API key - `GET /keys/{uidOrKey}`
//// - [ ] Delete API key - `DELETE /keys/{uidOrKey}`
//// - [ ] Update API key - `PATCH /keys/{uidOrKey}`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Retrieves a paginated list of all API keys.
///
/// - offset: number of keys to skip (default: 0)
/// - limit: maximum number of keys to return (default: 20)
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys)
pub fn get_keys(
  client: Client,
  offset: Int,
  limit: Int,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = offset
  let _ = limit
  let _ = send_request
  todo
}

/// Creates a new API key with the specified permissions.
///
/// - actions: list of permitted actions (e.g. `["documents.add", "search"]`)
/// - indexes: list of accessible index uids (use `["*"]` for all indexes)
/// - expires_at: optional RFC 3339 expiration date
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys)
pub fn create_key(
  client: Client,
  actions: List(String),
  indexes: List(String),
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = actions
  let _ = indexes
  let _ = send_request
  todo
}

/// Retrieves a single API key by its uid or key value.
///
/// - uid_or_key: the `uid` (UUID) or `key` (hex string) of the API key
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys)
pub fn get_key(
  client: Client,
  uid_or_key: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = uid_or_key
  let _ = send_request
  todo
}

/// Deletes an API key permanently.
///
/// - uid_or_key: the `uid` (UUID) or `key` (hex string) of the API key
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys)
pub fn delete_key(
  client: Client,
  uid_or_key: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = uid_or_key
  let _ = send_request
  todo
}

/// Updates an API key's name or description.
///
/// - uid_or_key: the `uid` (UUID) or `key` (hex string) of the API key
///
/// Only `name` and `description` can be updated. Actions, indexes, and
/// expiration date are immutable after creation.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/keys)
pub fn update_key(
  client: Client,
  uid_or_key: String,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = uid_or_key
  let _ = send_request
  todo
}
