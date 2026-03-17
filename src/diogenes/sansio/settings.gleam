import diogenes.{
  type Client, type Error, type MeilisearchResponse, JsonError,
  MeilisearchSingleResult, UnexpectedHttpStatusCodeError,
  meilisearch_error_from_json, task_parser,
}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/json
import gleam/option
import gleam/result
import internal/http_tooling.{create_base_request}

// Api functions ---------------------------------------------------------------------------

/// Builds a request to retrieve all settings for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Settings)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = list_all_settings(client, "movies")
/// ```
pub fn list_all_settings(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Settings), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings")
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 -> settings_list_from_json(body)
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update settings for the given index.
///
/// Only fields present in `settings` are modified. The operation is
/// asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_all_settings(client, "movies", settings)
/// ```
pub fn update_all_settings(
  client: Client,
  index_uid: String,
  settings: Settings,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let body = settings_list_to_json(settings)
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings")
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)
  #(request, task_parser)
}

/// Builds a request to retrieve the chat settings for the given index.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `200` — returns a `MeilisearchSingleResult(Chat)`
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = get_chat(client, "movies")
/// ```
pub fn get_chat(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(Chat), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Get)
  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, decode_chat()) {
          Ok(chat_params) -> Ok(MeilisearchSingleResult(chat_params))
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

/// Builds a request to update the chat settings for the given index.
///
/// Configures how the index is presented to the LLM, including description,
/// document template, and search parameters. The operation is asynchronous —
/// Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = update_chat(client, "movies", chat_settings)
/// ```
pub fn update_chat(
  client: Client,
  index_uid: String,
  chat_settings: Chat,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Patch)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(json.to_string(chat_to_json(chat_settings)))
  #(request, task_parser)
}

/// Builds a request to reset the chat settings for the given index to their default values.
///
/// The operation is asynchronous — Meilisearch enqueues it and returns a task.
///
/// Returns a tuple of the HTTP request and a parser function.
/// The parser handles:
/// - `202` — returns a `Task` with the enqueued task details
/// - `401` — unauthorized (invalid or missing API key)
/// - `404` — index not found
///
/// ## Example
/// ```gleam
/// let #(request, parser) = reset_chat(client, "movies")
/// ```
pub fn reset_chat(
  client: Client,
  index_uid: String,
) -> #(
  Request(String),
  fn(Int, String) -> Result(MeilisearchResponse(task), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/settings/chat")
    |> request.set_method(http.Delete)
  #(request, task_parser)
}

// Types ---------------------------------------------------------------------------------------------

pub type Settings {
  Settings(
    displayed_attributes: List(String),
    searchable_attributes: List(String),
    filterable_attributes: List(String),
    sortable_attributes: List(String),
    foreign_keys: List(ForeignKey),
    ranking_rules: List(RankingRule),
    stop_words: List(String),
    non_separator_tokens: List(String),
    separator_tokens: List(String),
    dictionary: List(String),
    synonyms: Dict(String, List(String)),
    distinct_attribute: String,
    proximity_precision: ProximityPrecision,
    typo_tolerance: TypoTolerance,
    faceting: Faceting,
    pagination: Pagination,
    embedders: Embedder,
    search_cutoff_ms: Int,
    localized_attribute: List(LocalizedAttribute),
    facet_search: Bool,
    prefix_search: PrefixSearch,
  )
}

pub type ForeignKey {
  ForeignKey(foreign_index_uid: String, field_name: String)
}

pub type PrefixSearch {
  IndexTime
  PrefixSearchDisabled
  UnexpectedPrefixSearch
}

pub type LocalizedAttribute {
  LocalizedAttribute(locales: List(Locales), attribute_patterns: List(String))
}

pub type RankingRule {
  Words
  Typo
  Proximity
  AttributeRank
  Sort
  WordPosition
  Exactness
  UnexpectedRule
}

pub type Pagination {
  Pagination(max_total_hits: Int)
}

pub type ProximityPrecision {
  ByWord
  ByAttribute
  UnexpectedProximityPrecision
}

pub type TypoTolerance {
  TypoTolerance(
    enabled: Bool,
    min_word_size_for_typo: MinWordSizeForTypo,
    disable_on_words: List(String),
    disable_on_attributes: List(String),
  )
}

pub type MinWordSizeForTypo {
  MinWordSizeForTypo(one_typo: Int, two_typos: Int)
}

pub type Faceting {
  Faceting(
    max_values_per_facet: Int,
    sort_facet_values_by: Dict(String, SortType),
  )
}

pub type SortType {
  Count
  Alpha
  UnexpectedSortType
}

pub type Embedder {
  Embedder(
    source: EmbedderSource,
    model: String,
    revision: option.Option(String),
    pooling: EmbedderPooling,
    api_key: String,
    dimensions: Int,
    binary_quantisized: Bool,
    document_template: String,
    document_template_max_bytes: Int,
    url: String,
    // TODO: for the following dicts Value in following dict is any
    indexing_fragments: Dict(String, String),
    search_fragments: Dict(String, String),
    request: Dict(String, String),
    response: Dict(String, String),
    // Not for this one
    headers: Dict(String, String),
    search_embedder: option.Option(Embedder),
    indexing_embedder: option.Option(Embedder),
    distribution: Distribution,
    chat: Chat,
  )
}

pub type EmbedderSource {
  OpenAi
  HuggingFace
  Ollama
  Rest
  Composite
  UserProvided
  UnexpectedSource
}

pub type EmbedderPooling {
  UseModel
  ForceCls
  ForceMean
  UnexpectedPooling
}

pub type Distribution {
  Distribution(current_mean: Float, current_sigma: Float)
}

pub type Chat {
  Chat(
    description: String,
    document_template: String,
    document_template_max_bytes: Int,
    search_parameters: ChatSearchParameters,
  )
}

pub type ChatSearchParameters {
  ChatSearchParameters(
    hybrid: ChatEmbedder,
    limit: Int,
    sort: List(String),
    distinct: String,
    matching_strategy: ChatMatchingStrategy,
    attributes_to_search_on: List(String),
    ranking_score_threshold: option.Option(Float),
  )
}

pub type ChatEmbedder {
  ChatEmbedder(embedder: String, semantic_ratio: Float)
}

pub type ChatMatchingStrategy {
  Last
  All
  Frequency
  UnexpectedChatMatchingStrategy
}

// Settings decoding function/json --------------------------------------------------------------------------

fn settings_list_from_json(
  settings: String,
) -> Result(MeilisearchResponse(Settings), Error) {
  json.parse(settings, decode_settings())
  |> result.map(MeilisearchSingleResult)
  |> result.map_error(JsonError)
}

fn decode_settings() -> decode.Decoder(Settings) {
  use displayed_attributes <- decode.field(
    "displayedAttributes",
    decode.list(decode.string),
  )
  use searchable_attributes <- decode.field(
    "searchableAttributes",
    decode.list(decode.string),
  )
  use filterable_attributes <- decode.field(
    "filterableAttributes",
    decode.list(decode.string),
  )
  use sortable_attributes <- decode.field(
    "sortableAttributes",
    decode.list(decode.string),
  )
  use foreign_keys <- decode.field(
    "foreignKeys",
    decode.list(decode_foreign_keys()),
  )
  use ranking_rules <- decode.field(
    "rankingRules",
    decode.list(
      decode.string
      |> decode.map(fn(value) { ranking_rule_from_string(value) }),
    ),
  )
  use stop_words <- decode.field("stopWords", decode.list(decode.string))
  use non_separator_tokens <- decode.field(
    "nonSeparatorTokens",
    decode.list(decode.string),
  )
  use separator_tokens <- decode.field(
    "separatorTokens",
    decode.list(decode.string),
  )
  use dictionary <- decode.field("dictionary", decode.list(decode.string))
  use synonyms <- decode.field(
    "synonyms",
    decode.dict(decode.string, decode.list(decode.string)),
  )
  use distinct_attribute <- decode.field("distinctAttribute", decode.string)
  use proximity_precision <- decode.field(
    "proximityPrecision",
    decode.string
      |> decode.map(fn(value) { proximity_precision_from_string(value) }),
  )
  use typo_tolerance <- decode.field(
    "typoTolerance",
    decode_typo_tolerance_decoder(),
  )
  use faceting <- decode.field("faceting", decode_faceting())
  use pagination <- decode.field("pagination", {
    use max_total_hits <- decode.field("maxTotalHits", decode.int)
    decode.success(Pagination(max_total_hits:))
  })

  use embedders <- decode.field("embedders", decode_embedder())
  use search_cutoff_ms <- decode.field("searchCutoffMs", decode.int)
  use localized_attribute <- decode.field(
    "localizedAttributes",
    decode.list(decode_localized_attribute()),
  )
  use facet_search <- decode.field("facetSearch", decode.bool)
  use prefix_search <- decode.field(
    "prefixSearch",
    decode.string
      |> decode.map(fn(value) {
        case value {
          "indexTime" -> IndexTime
          "disabled" -> PrefixSearchDisabled
          _ -> UnexpectedPrefixSearch
        }
      }),
  )

  decode.success(Settings(
    displayed_attributes:,
    searchable_attributes:,
    filterable_attributes:,
    sortable_attributes:,
    foreign_keys:,
    ranking_rules:,
    stop_words:,
    non_separator_tokens:,
    separator_tokens:,
    dictionary:,
    synonyms:,
    distinct_attribute:,
    proximity_precision:,
    typo_tolerance:,
    faceting:,
    pagination:,
    embedders:,
    search_cutoff_ms:,
    localized_attribute:,
    facet_search:,
    prefix_search:,
  ))
}

fn settings_list_to_json(settings: Settings) -> String {
  let object =
    json.object([
      #(
        "displayedAttributes",
        json.array(settings.displayed_attributes, json.string),
      ),
      #(
        "searchableAttributes",
        json.array(settings.searchable_attributes, json.string),
      ),
      #(
        "filterableAttributes",
        json.array(settings.filterable_attributes, json.string),
      ),
      #(
        "sortableAttributes",
        json.array(settings.sortable_attributes, json.string),
      ),
      #("foreignKeys", json.array(settings.foreign_keys, foreign_key_to_json)),
      #(
        "rankingRules",
        json.array(settings.ranking_rules, ranking_rule_to_json),
      ),
      #("stopWords", json.array(settings.stop_words, json.string)),
      #(
        "nonSeparatorTokens",
        json.array(settings.non_separator_tokens, json.string),
      ),
      #("separatorTokens", json.array(settings.separator_tokens, json.string)),
      #("dictionary", json.array(settings.dictionary, json.string)),
      #(
        "synonyms",
        json.dict(settings.synonyms, fn(v) { v }, fn(v) {
          json.array(v, json.string)
        }),
      ),
      #("distinctAttribute", json.string(settings.distinct_attribute)),
      #(
        "proximityPrecision",
        proximity_precision_to_json(settings.proximity_precision),
      ),
      #("typoTolerance", typo_tolerance_to_json(settings.typo_tolerance)),

      #("faceting", faceting_to_json(settings.faceting)),
      #("pagination", pagination_to_json(settings.pagination)),
      #("embedders", embedder_to_json(settings.embedders)),
      #("searchCutoffMs", json.int(settings.search_cutoff_ms)),
      #(
        "localizedAttributes",
        json.array(settings.localized_attribute, localized_attribute_to_json),
      ),
      #("facetSearch", json.bool(settings.facet_search)),
      #("prefixSearch", prefix_search_to_json(settings.prefix_search)),
    ])

  json.to_string(object)
}

fn prefix_search_to_json(prefix_search: PrefixSearch) -> json.Json {
  case prefix_search {
    IndexTime -> json.string("indexTime")
    PrefixSearchDisabled -> json.string("disabled")
    _ -> json.null()
  }
}

fn pagination_to_json(pagination: Pagination) -> json.Json {
  json.object([#("maxTotalHits", json.int(pagination.max_total_hits))])
}

fn decode_foreign_keys() -> decode.Decoder(ForeignKey) {
  use foreign_index_uid <- decode.field("foreignIndexUid", decode.string)
  use field_name <- decode.field("fieldName", decode.string)

  decode.success(ForeignKey(foreign_index_uid:, field_name:))
}

fn foreign_key_to_json(foreign_key: ForeignKey) -> json.Json {
  json.object([
    #("foreignIndexUid", json.string(foreign_key.foreign_index_uid)),
    #("fieldName", json.string(foreign_key.field_name)),
  ])
}

fn decode_localized_attribute() -> decode.Decoder(LocalizedAttribute) {
  use locales <- decode.field(
    "locales",
    decode.list(
      decode.string
      |> decode.map(locales_from_string),
    ),
  )
  use attribute_patterns <- decode.field(
    "attributePatterns",
    decode.list(decode.string),
  )

  decode.success(LocalizedAttribute(locales:, attribute_patterns:))
}

fn localized_attribute_to_json(
  localized_attribute: LocalizedAttribute,
) -> json.Json {
  json.object([
    #("locales", json.array(localized_attribute.locales, locales_to_json)),
    #(
      "attributePatterns",
      json.array(localized_attribute.attribute_patterns, json.string),
    ),
  ])
}

fn decode_embedder() -> decode.Decoder(Embedder) {
  use <- decode.recursive
  use source <- decode.field(
    "source",
    decode.string |> decode.map(decode_source),
  )
  use model <- decode.field("model", decode.string)
  use revision <- decode.field("revision", decode.optional(decode.string))
  use pooling <- decode.field(
    "pooling",
    decode.string |> decode.map(decode_pooling),
  )
  use api_key <- decode.field("apiKey", decode.string)
  use dimensions <- decode.field("dimensions", decode.int)
  use binary_quantisized <- decode.field("binaryQuantisized", decode.bool)
  use document_template <- decode.field("documentTemplate", decode.string)
  use document_template_max_bytes <- decode.field(
    "documentTemplateMaxBytes",
    decode.int,
  )
  use url <- decode.field("url", decode.string)
  use indexing_fragments <- decode.field(
    "indexingFragments",
    decode.dict(decode.string, decode.string),
  )
  use search_fragments <- decode.field(
    "searchFragments",
    decode.dict(decode.string, decode.string),
  )
  use request <- decode.field(
    "request",
    decode.dict(decode.string, decode.string),
  )
  use response <- decode.field(
    "response",
    decode.dict(decode.string, decode.string),
  )
  use headers <- decode.field(
    "headers",
    decode.dict(decode.string, decode.string),
  )
  use search_embedder <- decode.field(
    "searchEmbedder",
    decode.optional(decode_embedder()),
  )
  use indexing_embedder <- decode.field(
    "indexingEmbedder",
    decode.optional(decode_embedder()),
  )
  use distribution <- decode.field("distribution", {
    use current_mean <- decode.field("currentMean", decode.float)
    use current_sigma <- decode.field("currentSigma", decode.float)
    decode.success(Distribution(current_mean:, current_sigma:))
  })
  use chat <- decode.field("chat", decode_chat())

  decode.success(Embedder(
    source:,
    model:,
    revision:,
    pooling:,
    api_key:,
    dimensions:,
    binary_quantisized:,
    document_template:,
    document_template_max_bytes:,
    url:,
    indexing_fragments:,
    search_fragments:,
    request:,
    response:,
    headers:,
    search_embedder:,
    indexing_embedder:,
    distribution:,
    chat:,
  ))
}

fn decode_pooling(value: String) -> EmbedderPooling {
  case value {
    "useModel" -> UseModel
    "forceCls" -> ForceCls
    "forceMean" -> ForceMean
    _ -> UnexpectedPooling
  }
}

fn decode_source(value: String) -> EmbedderSource {
  case value {
    "openAi" -> OpenAi
    "huggingFace" -> HuggingFace
    "ollama" -> Ollama
    "rest" -> Rest
    "composite" -> Composite
    "userProvided" -> UserProvided
    _ -> UnexpectedSource
  }
}

fn embedder_to_json(embedder: Embedder) -> json.Json {
  json.object([
    #("source", embedder_source_to_json(embedder.source)),
    #("model", json.string(embedder.model)),
    #("revision", case embedder.revision {
      option.Some(revision) -> json.string(revision)
      option.None -> json.null()
    }),
    #("pooling", pooling_to_json(embedder.pooling)),
    #("apiKey", json.string(embedder.api_key)),
    #("dimensions", json.int(embedder.dimensions)),
    #("binaryQuantized", json.bool(embedder.binary_quantisized)),
    #("documentTemplate", json.string(embedder.document_template)),
    #(
      "documentTemplateMaxBytes",
      json.int(embedder.document_template_max_bytes),
    ),
    #("url", json.string(embedder.url)),
    #(
      "indexingFragments",
      json.dict(embedder.indexing_fragments, fn(k) { k }, fn(v) {
        json.string(v)
      }),
    ),
    #(
      "searchFragments",
      json.dict(embedder.search_fragments, fn(k) { k }, fn(v) { json.string(v) }),
    ),
    #(
      "request",
      json.dict(embedder.request, fn(k) { k }, fn(v) { json.string(v) }),
    ),
    #(
      "response",
      json.dict(embedder.response, fn(k) { k }, fn(v) { json.string(v) }),
    ),
    #(
      "headers",
      json.dict(embedder.headers, fn(k) { k }, fn(v) { json.string(v) }),
    ),
    #("searchEmbedder", case embedder.search_embedder {
      option.Some(embedder) -> embedder_to_json(embedder)
      option.None -> json.null()
    }),
    #("indexingEmbedder", case embedder.indexing_embedder {
      option.Some(embedder) -> embedder_to_json(embedder)
      option.None -> json.null()
    }),
    #("distribution", distribution_to_json(embedder.distribution)),
    #("chat", chat_to_json(embedder.chat)),
  ])
}

fn pooling_to_json(pooling: EmbedderPooling) -> json.Json {
  case pooling {
    UseModel -> json.string("useModel")
    ForceCls -> json.string("forceCls")
    ForceMean -> json.string("forceMean")
    UnexpectedPooling -> json.null()
  }
}

fn embedder_source_to_json(source: EmbedderSource) -> json.Json {
  case source {
    OpenAi -> json.string("openAi")
    HuggingFace -> json.string("huggingFace")
    Ollama -> json.string("ollama")
    Rest -> json.string("rest")
    Composite -> json.string("composite")
    UserProvided -> json.string("userProvided")
    UnexpectedSource -> json.null()
  }
}

fn distribution_to_json(distribution: Distribution) -> json.Json {
  json.object([
    #("currentMean", json.float(distribution.current_mean)),
    #("currentSigma", json.float(distribution.current_sigma)),
  ])
}

fn decode_chat() -> decode.Decoder(Chat) {
  use description <- decode.field("description", decode.string)
  use document_template <- decode.field("documentTemplate", decode.string)
  use document_template_max_bytes <- decode.field(
    "documentTemplateMaxBytes",
    decode.int,
  )
  use search_parameters <- decode.field(
    "searchParameters",
    decode_chat_search_parameters(),
  )
  decode.success(Chat(
    description:,
    document_template:,
    document_template_max_bytes:,
    search_parameters:,
  ))
}

fn decode_chat_search_parameters() -> decode.Decoder(ChatSearchParameters) {
  use hybrid <- decode.field("hybrid", decode_chat_embedder())
  use limit <- decode.field("limit", decode.int)
  use sort <- decode.field("sort", decode.list(decode.string))
  use distinct <- decode.field("distinct", decode.string)
  use matching_strategy <- decode.field(
    "matchingStrategy",
    decode.string |> decode.map(chat_matching_strategy_from_string),
  )
  use attributes_to_search_on <- decode.field(
    "attributesToSearchOn",
    decode.list(decode.string),
  )
  use ranking_score_threshold <- decode.field(
    "rankingScoreThreshold",
    decode.optional(decode.float),
  )
  decode.success(ChatSearchParameters(
    hybrid:,
    limit:,
    sort:,
    distinct:,
    matching_strategy:,
    attributes_to_search_on:,
    ranking_score_threshold:,
  ))
}

fn decode_chat_embedder() -> decode.Decoder(ChatEmbedder) {
  use embedder <- decode.field("embedder", decode.string)
  use semantic_ratio <- decode.field("semanticRatio", decode.float)
  decode.success(ChatEmbedder(embedder:, semantic_ratio:))
}

fn chat_matching_strategy_from_string(value: String) -> ChatMatchingStrategy {
  case value {
    "last" -> Last
    "all" -> All
    "frequency" -> Frequency
    _ -> UnexpectedChatMatchingStrategy
  }
}

fn chat_to_json(chat: Chat) -> json.Json {
  json.object([
    #("description", json.string(chat.description)),
    #("documentTemplate", json.string(chat.document_template)),
    #("documentTemplateMaxBytes", json.int(chat.document_template_max_bytes)),
    #(
      "searchParameters",
      chat_search_parameters_to_json(chat.search_parameters),
    ),
  ])
}

fn chat_search_parameters_to_json(params: ChatSearchParameters) -> json.Json {
  json.object([
    #("hybrid", chat_embedder_to_json(params.hybrid)),
    #("limit", json.int(params.limit)),
    #("sort", json.array(params.sort, json.string)),
    #("distinct", json.string(params.distinct)),
    #(
      "matchingStrategy",
      chat_matching_strategy_to_json(params.matching_strategy),
    ),
    #(
      "attributesToSearchOn",
      json.array(params.attributes_to_search_on, json.string),
    ),
    #("rankingScoreThreshold", case params.ranking_score_threshold {
      option.Some(ranking_score_threshold) ->
        json.float(ranking_score_threshold)
      option.None -> json.null()
    }),
  ])
}

fn chat_embedder_to_json(chat_embedder: ChatEmbedder) -> json.Json {
  json.object([
    #("embedder", json.string(chat_embedder.embedder)),
    #("semanticRatio", json.float(chat_embedder.semantic_ratio)),
  ])
}

fn chat_matching_strategy_to_json(strategy: ChatMatchingStrategy) -> json.Json {
  case strategy {
    Last -> json.string("last")
    All -> json.string("all")
    Frequency -> json.string("frequency")
    UnexpectedChatMatchingStrategy -> json.null()
  }
}

fn decode_faceting() -> decode.Decoder(Faceting) {
  use max_values_per_facet <- decode.field("maxValuesPerFacet", decode.int)
  use sort_facet_values_by <- decode.field(
    "sortFacetValuesBy",
    decode.dict(
      decode.string,
      decode.string
        |> decode.map(fn(value) {
          case value {
            "count" -> Count
            "alpha" -> Alpha
            _ -> UnexpectedSortType
          }
        }),
    ),
  )
  decode.success(Faceting(max_values_per_facet:, sort_facet_values_by:))
}

fn faceting_to_json(faceting: Faceting) -> json.Json {
  json.object([
    #("maxValuesPerFacet", json.int(faceting.max_values_per_facet)),
    #(
      "sortFacetValuesBy",
      json.dict(faceting.sort_facet_values_by, fn(k) { k }, fn(v) {
        case v {
          Count -> json.string("count")
          Alpha -> json.string("alpha")
          UnexpectedSortType -> json.null()
        }
      }),
    ),
  ])
}

fn ranking_rule_from_string(ranking_rule: String) -> RankingRule {
  case ranking_rule {
    "words" -> Words
    "typo" -> Typo
    "proximity" -> Proximity
    "attribute" -> AttributeRank
    "sort" -> Sort
    "wordPosition" -> WordPosition
    "exactness" -> Exactness
    _ -> UnexpectedRule
  }
}

fn ranking_rule_to_json(ranking_rule: RankingRule) -> json.Json {
  case ranking_rule {
    Words -> json.string("words")
    Typo -> json.string("typo")
    Proximity -> json.string("proximity")
    AttributeRank -> json.string("attribute")
    Sort -> json.string("sort")
    WordPosition -> json.string("wordPosition")
    Exactness -> json.string("exactness")
    UnexpectedRule -> json.null()
  }
}

fn proximity_precision_from_string(
  proximity_precision: String,
) -> ProximityPrecision {
  case proximity_precision {
    "byWord" -> ByWord
    "byAttribute" -> ByAttribute
    _ -> UnexpectedProximityPrecision
  }
}

fn proximity_precision_to_json(
  proximity_precision: ProximityPrecision,
) -> json.Json {
  case proximity_precision {
    ByWord -> json.string("byWord")
    ByAttribute -> json.string("byAttribute")
    UnexpectedProximityPrecision -> json.null()
  }
}

fn decode_typo_tolerance_decoder() -> decode.Decoder(TypoTolerance) {
  {
    use enabled <- decode.field("enabled", decode.bool)
    use min_word_size_for_typo <- decode.field(
      "minWordSizeForTypos",
      min_word_size_for_typo_decoder(),
    )
    use disable_on_words <- decode.field(
      "disableOnWords",
      decode.list(decode.string),
    )
    use disable_on_attributes <- decode.field(
      "disableOnAttributes",
      decode.list(decode.string),
    )

    decode.success(TypoTolerance(
      enabled:,
      min_word_size_for_typo:,
      disable_on_words:,
      disable_on_attributes:,
    ))
  }
}

fn typo_tolerance_to_json(typo_tolerance: TypoTolerance) -> json.Json {
  json.object([
    #("enabled", json.bool(typo_tolerance.enabled)),
    #(
      "minWordSizeForTypos",
      json.object([
        #("oneTypo", json.int(typo_tolerance.min_word_size_for_typo.one_typo)),
        #("twoTypos", json.int(typo_tolerance.min_word_size_for_typo.two_typos)),
      ]),
    ),
    #(
      "disableOnWords",
      json.array(typo_tolerance.disable_on_words, json.string),
    ),
    #(
      "disableOnAttributes",
      json.array(typo_tolerance.disable_on_attributes, json.string),
    ),
  ])
}

fn min_word_size_for_typo_decoder() -> decode.Decoder(MinWordSizeForTypo) {
  use one_typo <- decode.field("oneTypo", decode.int)
  use two_typos <- decode.field("twoTypos", decode.int)

  decode.success(MinWordSizeForTypo(one_typo:, two_typos:))
}

// Locales Type, encoder, decoder ---------------------------------------------------------------

pub type Locales {
  Af
  Ak
  Am
  Ar
  Az
  Be
  Bn
  Bg
  Ca
  Cs
  Da
  De
  El
  En
  Eo
  Et
  Fi
  Fr
  Gu
  He
  Hi
  Hr
  Hu
  Hy
  Id
  It
  Jv
  Ja
  Kn
  Ka
  Km
  Ko
  La
  Lv
  Lt
  Ml
  Mr
  Mk
  My
  Ne
  Nl
  Nb
  Or
  Pa
  Fa
  Pl
  Pt
  Ro
  Ru
  Si
  Sk
  Sl
  Sn
  Es
  Sr
  Sv
  Ta
  Te
  Tl
  Th
  Tk
  Tr
  Uk
  Ur
  Uz
  Vi
  Yi
  Zh
  Zu
  Afr
  Aka
  Amh
  Ara
  Aze
  Bel
  Ben
  Bul
  Cat
  Ces
  Dan
  Deu
  Ell
  Eng
  Epo
  Est
  Fin
  Fra
  Guj
  Heb
  Hin
  Hrv
  Hun
  Hye
  Ind
  Ita
  Jav
  Jpn
  Kan
  Kat
  Khm
  Kor
  Lat
  Lav
  Lit
  Mal
  Mar
  Mkd
  Mya
  Nep
  Nld
  Nob
  Ori
  Pan
  Pes
  Pol
  Por
  Ron
  Rus
  Sin
  Slk
  Slv
  Sna
  Spa
  Srp
  Swe
  Tam
  Tel
  Tgl
  Tha
  Tuk
  Tur
  Ukr
  Urd
  Uzb
  Vie
  Yid
  Zho
  Zul
  Cmn
  UnexpectedLocal
}

pub fn locales_to_json(locale: Locales) -> json.Json {
  let local_string = case locale {
    Af -> "af"
    Ak -> "ak"
    Am -> "am"
    Ar -> "ar"
    Az -> "az"
    Be -> "be"
    Bn -> "bn"
    Bg -> "bg"
    Ca -> "ca"
    Cs -> "cs"
    Da -> "da"
    De -> "de"
    El -> "el"
    En -> "en"
    Eo -> "eo"
    Et -> "et"
    Fi -> "fi"
    Fr -> "fr"
    Gu -> "gu"
    He -> "he"
    Hi -> "hi"
    Hr -> "hr"
    Hu -> "hu"
    Hy -> "hy"
    Id -> "id"
    It -> "it"
    Jv -> "jv"
    Ja -> "ja"
    Kn -> "kn"
    Ka -> "ka"
    Km -> "km"
    Ko -> "ko"
    La -> "la"
    Lv -> "lv"
    Lt -> "lt"
    Ml -> "ml"
    Mr -> "mr"
    Mk -> "mk"
    My -> "my"
    Ne -> "ne"
    Nl -> "nl"
    Nb -> "nb"
    Or -> "or"
    Pa -> "pa"
    Fa -> "fa"
    Pl -> "pl"
    Pt -> "pt"
    Ro -> "ro"
    Ru -> "ru"
    Si -> "si"
    Sk -> "sk"
    Sl -> "sl"
    Sn -> "sn"
    Es -> "es"
    Sr -> "sr"
    Sv -> "sv"
    Ta -> "ta"
    Te -> "te"
    Tl -> "tl"
    Th -> "th"
    Tk -> "tk"
    Tr -> "tr"
    Uk -> "uk"
    Ur -> "ur"
    Uz -> "uz"
    Vi -> "vi"
    Yi -> "yi"
    Zh -> "zh"
    Zu -> "zu"
    Afr -> "afr"
    Aka -> "aka"
    Amh -> "amh"
    Ara -> "ara"
    Aze -> "aze"
    Bel -> "bel"
    Ben -> "ben"
    Bul -> "bul"
    Cat -> "cat"
    Ces -> "ces"
    Dan -> "dan"
    Deu -> "deu"
    Ell -> "ell"
    Eng -> "eng"
    Epo -> "epo"
    Est -> "est"
    Fin -> "fin"
    Fra -> "fra"
    Guj -> "guj"
    Heb -> "heb"
    Hin -> "hin"
    Hrv -> "hrv"
    Hun -> "hun"
    Hye -> "hye"
    Ind -> "ind"
    Ita -> "ita"
    Jav -> "jav"
    Jpn -> "jpn"
    Kan -> "kan"
    Kat -> "kat"
    Khm -> "khm"
    Kor -> "kor"
    Lat -> "lat"
    Lav -> "lav"
    Lit -> "lit"
    Mal -> "mal"
    Mar -> "mar"
    Mkd -> "mkd"
    Mya -> "mya"
    Nep -> "nep"
    Nld -> "nld"
    Nob -> "nob"
    Ori -> "ori"
    Pan -> "pan"
    Pes -> "pes"
    Pol -> "pol"
    Por -> "por"
    Ron -> "ron"
    Rus -> "rus"
    Sin -> "sin"
    Slk -> "slk"
    Slv -> "slv"
    Sna -> "sna"
    Spa -> "spa"
    Srp -> "srp"
    Swe -> "swe"
    Tam -> "tam"
    Tel -> "tel"
    Tgl -> "tgl"
    Tha -> "tha"
    Tuk -> "tuk"
    Tur -> "tur"
    Ukr -> "ukr"
    Urd -> "urd"
    Uzb -> "uzb"
    Vie -> "vie"
    Yid -> "yid"
    Zho -> "zho"
    Zul -> "zul"
    Cmn -> "cmn"
    UnexpectedLocal -> ""
  }
  json.string(local_string)
}

fn locales_from_string(value: String) -> Locales {
  case value {
    "af" -> Af
    "ak" -> Ak
    "am" -> Am
    "ar" -> Ar
    "az" -> Az
    "be" -> Be
    "bn" -> Bn
    "bg" -> Bg
    "ca" -> Ca
    "cs" -> Cs
    "da" -> Da
    "de" -> De
    "el" -> El
    "en" -> En
    "eo" -> Eo
    "et" -> Et
    "fi" -> Fi
    "fr" -> Fr
    "gu" -> Gu
    "he" -> He
    "hi" -> Hi
    "hr" -> Hr
    "hu" -> Hu
    "hy" -> Hy
    "id" -> Id
    "it" -> It
    "jv" -> Jv
    "ja" -> Ja
    "kn" -> Kn
    "ka" -> Ka
    "km" -> Km
    "ko" -> Ko
    "la" -> La
    "lv" -> Lv
    "lt" -> Lt
    "ml" -> Ml
    "mr" -> Mr
    "mk" -> Mk
    "my" -> My
    "ne" -> Ne
    "nl" -> Nl
    "nb" -> Nb
    "or" -> Or
    "pa" -> Pa
    "fa" -> Fa
    "pl" -> Pl
    "pt" -> Pt
    "ro" -> Ro
    "ru" -> Ru
    "si" -> Si
    "sk" -> Sk
    "sl" -> Sl
    "sn" -> Sn
    "es" -> Es
    "sr" -> Sr
    "sv" -> Sv
    "ta" -> Ta
    "te" -> Te
    "tl" -> Tl
    "th" -> Th
    "tk" -> Tk
    "tr" -> Tr
    "uk" -> Uk
    "ur" -> Ur
    "uz" -> Uz
    "vi" -> Vi
    "yi" -> Yi
    "zh" -> Zh
    "zu" -> Zu
    "afr" -> Afr
    "aka" -> Aka
    "amh" -> Amh
    "ara" -> Ara
    "aze" -> Aze
    "bel" -> Bel
    "ben" -> Ben
    "bul" -> Bul
    "cat" -> Cat
    "ces" -> Ces
    "dan" -> Dan
    "deu" -> Deu
    "ell" -> Ell
    "eng" -> Eng
    "epo" -> Epo
    "est" -> Est
    "fin" -> Fin
    "fra" -> Fra
    "guj" -> Guj
    "heb" -> Heb
    "hin" -> Hin
    "hrv" -> Hrv
    "hun" -> Hun
    "hye" -> Hye
    "ind" -> Ind
    "ita" -> Ita
    "jav" -> Jav
    "jpn" -> Jpn
    "kan" -> Kan
    "kat" -> Kat
    "khm" -> Khm
    "kor" -> Kor
    "lat" -> Lat
    "lav" -> Lav
    "lit" -> Lit
    "mal" -> Mal
    "mar" -> Mar
    "mkd" -> Mkd
    "mya" -> Mya
    "nep" -> Nep
    "nld" -> Nld
    "nob" -> Nob
    "ori" -> Ori
    "pan" -> Pan
    "pes" -> Pes
    "pol" -> Pol
    "por" -> Por
    "ron" -> Ron
    "rus" -> Rus
    "sin" -> Sin
    "slk" -> Slk
    "slv" -> Slv
    "sna" -> Sna
    "spa" -> Spa
    "srp" -> Srp
    "swe" -> Swe
    "tam" -> Tam
    "tel" -> Tel
    "tgl" -> Tgl
    "tha" -> Tha
    "tuk" -> Tuk
    "tur" -> Tur
    "ukr" -> Ukr
    "urd" -> Urd
    "uzb" -> Uzb
    "vie" -> Vie
    "yid" -> Yid
    "zho" -> Zho
    "zul" -> Zul
    "cmn" -> Cmn
    _ -> UnexpectedLocal
  }
}
