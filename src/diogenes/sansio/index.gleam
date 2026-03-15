import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  MeilisearchSingleResult, UnexpectedHttpStatusCodeError,
  meilisearch_error_from_json, meilisearch_results_from_json, task_from_json,
}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/json
import gleam/option.{type Option}
import internal/http_tooling.{create_base_request}

pub type Index {
  IndexCreation(uid: String, primary_key: Option(String))
  IndexUpdate(uid: String, new_uid: Option(String), primary_key: Option(String))
  IndexPairSwap(index_a: String, index_b: String, rename: Bool)
  IndexFields(List(IndexField))
  IndexListFieldsRequest(offset: Int, limit: Int, filter: IndexListFilters)
  Index(
    uid: String,
    primary_key: Option(String),
    created_at: String,
    updated_at: String,
  )
}

pub type IndexListFilters {
  IndexListFilters(
    attribute_patterns: List(String),
    displayed: Bool,
    searchable: Bool,
    sortable: Bool,
    distinct: Bool,
    filterable: Bool,
  )
}

pub type AttributePatterns {
  AttributePatterns(patterns: List(String))
}

pub type IndexField {

  IndexField(
    name: String,
    displayed: Displayed,
    searchable: Searchable,
    sortable: Sortable,
    distinct: Distinct,
    ranking_rule: RankingRule,
    filterable: Filterable,
    localized: Localized,
  )
}

pub type Displayed {
  Displayed(enabled: Bool)
}

pub type Searchable {
  Searchable(enabled: Bool)
}

pub type Sortable {
  Sortable(enabled: Bool)
}

pub type Distinct {
  Distinct(enabled: Bool)
}

pub type RankingRule {
  RankingRule(enabled: Bool, order: List(String))
}

pub type Filterable {
  Filterable(
    enabled: Bool,
    sort_by: String,
    facet_search: Bool,
    equality: Bool,
    comparison: Bool,
  )
}

pub type Localized {
  Localized(locales: List(String))
}

/// Creates a Meilisearch index
///
/// - uid: unique index identifier
/// - primary_key: id from the document to references as a primary_key
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/create-index)
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
    |> request.set_header("Content-Type", "application/json")

  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(JsonError(err))
        }
      401 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
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

/// Updates an existing index's primary key or UID
///
/// - uid: unique identifier of the index to update
/// - new_uid: new UID to rename the index (optional)
/// - primary_key: new primary key for the index (optional)
///
/// The primary key cannot be changed if the index already contains documents.
/// Returns a 404 error if the index does not exist.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/update-index)
pub fn update_index(
  client: Client,
  uid: String,
  new_uid: Option(String),
  primary_key: Option(String),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let body =
    json.to_string(
      index_update_to_json(IndexUpdate(uid:, new_uid:, primary_key:)),
    )

  let request =
    create_base_request(client, "/indexes/" <> uid)
    |> request.set_body(body)
    |> request.set_method(http.Patch)

  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(JsonError(err))
        }
      401 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

fn index_update_to_json(idx: Index) -> json.Json {
  let assert IndexUpdate(..) = idx
  json.object([
    #("uid", case idx.new_uid {
      option.Some(uid) -> json.string(uid)
      option.None -> json.null()
    }),
    #("primaryKey", case idx.primary_key {
      option.Some(pk) -> json.string(pk)
      option.None -> json.null()
    }),
  ])
}

/// Retrieves the metadata of a single index
///
/// - uid: unique index identifier
///
/// Returns the index uid, primary key, and creation/update timestamps.
/// Returns a 404 error if the index does not exist.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/get-index)
pub fn get_index(
  client: Client,
  uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Index), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> uid)
    |> request.set_method(http.Get)

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, index_decoder()) {
          Ok(index) -> Ok(MeilisearchSingleResult(result: index))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Deletes a Meilisearch index and all its documents
///
/// - uid: unique index identifier
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/delete-index)
pub fn delete_index(
  client: Client,
  uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(a), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> uid)
    |> request.set_method(http.Delete)

  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(JsonError(err))
        }
      401 -> Error(meilisearch_error_from_json(body))
      404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
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

/// Lists all Meilisearch indexes with pagination
///
/// - offset: number of indexes to skip (defaults to 0)
/// - limit: maximum number of indexes to return (defaults to 20)
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/list-all-indexes)
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
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

fn list_index_from_json(
  body: String,
) -> Result(MeilisearchResponse(Index), Error) {
  meilisearch_results_from_json(body, index_decoder())
}

fn index_decoder() -> decode.Decoder(Index) {
  use uid <- decode.field("uid", decode.string)
  use primary_key <- decode.field("primaryKey", decode.optional(decode.string))
  use created_at <- decode.field("createdAt", decode.string)
  use updated_at <- decode.field("updatedAt", decode.string)

  decode.success(Index(uid:, primary_key:, created_at:, updated_at:))
}

/// Swaps the documents, settings, and task history of two or more index pairs
///
/// - index_pairs: list of IndexPairSwap values, each pairing two index UIDs to swap
///
/// All swaps in a single request are atomic: either all succeed or none do.
/// A single request can include multiple swap pairs.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes)
pub fn swap_index(
  client: Client,
  index_pairs: List(Index),
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let body = json.to_string(json.array(index_pairs, index_pair_swap_to_json))
  let request =
    create_base_request(client, "/swap-indexes")
    |> request.set_method(http.Post)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  let parser = fn(status: Int, body: String) {
    case status {
      202 ->
        case task_from_json(body) {
          Ok(task) -> Ok(task)
          Error(err) -> Error(JsonError(err))
        }
      401 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

fn index_pair_swap_to_json(pairs: Index) -> json.Json {
  let assert IndexPairSwap(..) = pairs
  json.object([
    #("indexes", json.array([pairs.index_a, pairs.index_b], json.string)),
    #("rename", json.bool(pairs.rename)),
  ])
}

/// Retrieves a paginated list of fields within an index, along with metadata about each field's configuration
///
/// - uid: unique identifier of the target index
/// - filters: filter criteria such as offset, limit, and attribute filters (displayed, searchable, sortable, filterable, etc.)
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/indexes/list-index-fields)
pub fn list_index_fields(
  client: Client,
  uid: String,
  filters: Index,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(IndexField), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> uid <> "/fields")
    |> request.set_method(http.Post)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(list_index_request_to_json(filters))

  let decoder = fn(status: Int, body: String) {
    case status {
      200 -> meilisearch_results_from_json(body, index_field_from_json())
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, decoder)
}

fn list_index_request_to_json(request: Index) -> String {
  let assert IndexListFieldsRequest(..) = request
  let request_object =
    json.object([
      #("filter", filters_to_json(request.filter)),
      #("offset", json.int(request.offset)),
      #("limit", json.int(request.limit)),
    ])

  json.to_string(request_object)
}

fn filters_to_json(filters: IndexListFilters) -> json.Json {
  json.object([
    #(
      "attributePatterns",
      attribute_patterns_to_json(filters.attribute_patterns),
    ),
    #("displayed", case filters.displayed {
      True -> json.bool(True)
      False -> json.null()
    }),
    #("searchable", case filters.searchable {
      True -> json.bool(True)
      False -> json.null()
    }),
    #("sortable", case filters.sortable {
      True -> json.bool(True)
      False -> json.null()
    }),
    #("distinct", case filters.distinct {
      True -> json.bool(True)
      False -> json.null()
    }),
    #("rankingRule", case filters.distinct {
      True -> json.bool(True)
      False -> json.null()
    }),
    #("filterable", case filters.distinct {
      True -> json.bool(True)
      False -> json.null()
    }),
  ])
}

//fn attribute_patterns_to_json(patterns: AttributePatterns) -> json.Json {
fn attribute_patterns_to_json(patterns: List(String)) -> json.Json {
  //json.object([#("patterns", json.array(patterns.patterns, json.string))])
  json.array(patterns, json.string)
}

fn index_field_from_json() -> decode.Decoder(IndexField) {
  use name <- decode.field("name", decode.string)
  use displayed <- decode.field("displayed", decode_displayed())
  use searchable <- decode.field("searchable", decode_searchable())
  use sortable <- decode.field("sortable", decode_sortable())
  use distinct <- decode.field("distinct", decode_distinct())
  use ranking_rule <- decode.field("rankingRule", decode_ranking_rule())
  use filterable <- decode.field("filterable", decode_filterable())
  use localized <- decode.field("localized", decode_localized())

  decode.success(IndexField(
    name:,
    displayed:,
    searchable:,
    sortable:,
    distinct:,
    ranking_rule:,
    filterable:,
    localized:,
  ))
}

fn decode_localized() -> decode.Decoder(Localized) {
  use locales <- decode.field("locales", decode.list(decode.string))
  decode.success(Localized(locales:))
}

fn decode_filterable() -> decode.Decoder(Filterable) {
  use enabled <- decode.field("enabled", decode.bool)
  use sort_by <- decode.field("sortBy", decode.string)
  use facet_search <- decode.field("facetSearch", decode.bool)
  use equality <- decode.field("equality", decode.bool)
  use comparison <- decode.field("comparison", decode.bool)

  decode.success(Filterable(
    enabled:,
    sort_by:,
    facet_search:,
    equality:,
    comparison:,
  ))
}

fn decode_ranking_rule() -> decode.Decoder(RankingRule) {
  use enabled <- decode.field("enabled", decode.bool)
  use order <- decode.field("order", decode.list(decode.string))
  decode.success(RankingRule(enabled:, order:))
}

fn decode_displayed() -> decode.Decoder(Displayed) {
  use enabled <- decode.field("enabled", decode.bool)
  decode.success(Displayed(enabled:))
}

fn decode_searchable() -> decode.Decoder(Searchable) {
  use enabled <- decode.field("enabled", decode.bool)
  decode.success(Searchable(enabled:))
}

fn decode_sortable() -> decode.Decoder(Sortable) {
  use enabled <- decode.field("enabled", decode.bool)
  decode.success(Sortable(enabled:))
}

fn decode_distinct() -> decode.Decoder(Distinct) {
  use enabled <- decode.field("enabled", decode.bool)
  decode.success(Distinct(enabled:))
}
