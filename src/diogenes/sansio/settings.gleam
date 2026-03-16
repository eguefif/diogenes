import diogenes.{
  type Client, type Error, type MeilisearchResponse,
  UnexpectedHttpStatusCodeError, meilisearch_error_from_json,
  meilisearch_results_from_json,
}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/option
import internal/http_tooling.{create_base_request}

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

pub type Settings {
  Settings(
    displayed_attributes: List(String),
    searchable_attributes: List(String),
    filterable_attributes: List(String),
    sortable_attributes: List(String),
    ranking_rules: List(RankingRule),
    stop_words: List(String),
    non_separator_tokens: List(String),
    separator_tokens: List(String),
    dictionnary: List(String),
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

pub type Faceting {
  Faceting(
    max_values_per_facet: Int,
    sort_facet_values_by: Dict(String, SortType),
  )
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
    search_embedder: Embedder,
    indexing_embedder: Embedder,
    distribution: Distribution,
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

pub type SortType {
  Count
  Alpha
  UnexpectedSortType
}

pub type Distribution {
  Distribution(current_mean: Int, current_sigma: Int)
}

pub type MinWordSizeForTypo {
  MinWordSizeForTypo(one_typo: Int, two_typos: Int)
}

//TODO: 
// - [ ] create all types for each object settings
// - [ ] create corresponding json decoder
// - [ ] Then create Settings type that gather them all and its decoder
// - [ ] Filterable: handle object attributes

fn settings_list_from_json(
  settings: String,
) -> Result(MeilisearchResponse(Settings), Error) {
  meilisearch_results_from_json(settings, decode_settings())
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
  use dictionnary <- decode.field("dictionnary", decode.list(decode.string))
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
    "localizedAttribute",
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
    ranking_rules:,
    stop_words:,
    non_separator_tokens:,
    separator_tokens:,
    dictionnary:,
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

fn decode_embedder() -> decode.Decoder(Embedder) {
  use <- decode.recursive
  use source <- decode.field(
    "embedderSource",
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
  use document_template <- decode.field("documenTemplate", decode.string)
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
  use search_embedders <- decode.field("searchEmbedder", decode_embedder())
  use indexing_embedders <- decode.field("indexingEmbedder", decode_embedder())
  use distribution <- decode.field("distribution", {
    use current_mean <- decode.field("currentMean", decode.int)
    use current_sigma <- decode.field("currentSigma", decode.int)
    decode.success(Distribution(current_mean:, current_sigma:))
  })

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
    search_embedders:,
    indexing_embedders:,
    distribution:,
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

fn decode_faceting() -> decode.Decoder(Faceting) {
  use max_values_per_facet <- decode.field("maxValuesPerFacet", decode.int)
  use sort_facet_values_by <- decode.field(
    "sortFacetValueBy",
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

fn ranking_rule_from_string(ranking_rule: String) -> RankingRule {
  case ranking_rule {
    "words" -> Words
    "type" -> Typo
    "proximity" -> Proximity
    "sort" -> Sort
    "wordPosition" -> WordPosition
    "exactness" -> Exactness
    _ -> UnexpectedRule
  }
}

//fn ranking_rule_to_string(ranking_rule: RankingRule) -> String {
//  case ranking_rule {
//    Words -> "words"
//    Typo -> "typo"
//    Proximity -> "proximity"
//    AttributeRank -> "attributeRank"
//    Sort -> "sort"
//    WordPosition -> "wordPosition"
//    Exactness -> "exacteness"
//    UnexpectedRule -> ""
//  }
//}

fn proximity_precision_from_string(
  proximity_precision: String,
) -> ProximityPrecision {
  case proximity_precision {
    "byWord" -> ByWord
    "byAttribute" -> ByAttribute
    _ -> UnexpectedProximityPrecision
  }
}

//fn proximity_precision_to_string(
//  proximity_precision: ProximityPrecision,
//) -> String {
//  case proximity_precision {
//    ByWord -> "byWord"
//    ByAttribute -> "byAttribute"
//    UnexpectedProximityPrecision -> ""
//  }
//}

fn decode_typo_tolerance_decoder() -> decode.Decoder(TypoTolerance) {
  {
    use enabled <- decode.field("enabled", decode.bool)
    use min_word_size_for_typo <- decode.field(
      "minWordSizeForTypo",
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

pub fn locales_to_string(locale: Locales) -> String {
  case locale {
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
