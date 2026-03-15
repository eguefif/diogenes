# Diogenes - API Coverage TODO

## Health

- [x] Get health - `GET /health`

## Indexes

- [x] List indexes - `GET /indexes`
- [x] Create index - `POST /indexes`
- [x] Get index - `GET /indexes/{indexUid}`
- [x] Delete index - `DELETE /indexes/{indexUid}`
- [x] Update index - `PATCH /indexes/{indexUid}`
- [x] Swap indexes - `POST /swap-indexes`
- [x] List index fields - `POST /indexes/{indexUid}/fields`

## Documents

- [x] Get documents - `GET /indexes/{indexUid}/documents`
- [ ] Get documents with POST - `POST /indexes/{indexUid}/documents/fetch`
- [ ] Get one document - `GET /indexes/{indexUid}/documents/{documentId}`
- [x] Add or replace documents - `POST /indexes/{indexUid}/documents`
- [ ] Add or update documents - `PUT /indexes/{indexUid}/documents`
- [ ] Delete all documents - `DELETE /indexes/{indexUid}/documents`
- [ ] Delete documents by batch - `POST /indexes/{indexUid}/delete-batch`
- [ ] Delete documents by filter - `POST /indexes/{indexUid}/documents/delete`
- [ ] Delete a document - `DELETE /indexes/{indexUid}/documents/{documentId}`
- [ ] Edit documents by function - `POST /indexes/{indexUid}/documents/edit`

## Search

- [ ] Search with GET - `GET /indexes/{indexUid}/search`
- [ ] Search with POST - `POST /indexes/{indexUid}/search`
- [ ] Multi-search - `POST /multi-search`

## Facet Search

- [ ] Perform a facet search - `POST /indexes/{indexUid}/facet-search`

## Similar Documents

- [ ] Get similar documents with GET - `GET /indexes/{indexUid}/similar`
- [ ] Get similar documents with POST - `POST /indexes/{indexUid}/similar`

## Settings

- [ ] Get all settings - `GET /indexes/{indexUid}/settings`
- [ ] Update settings - `PATCH /indexes/{indexUid}/settings`
- [ ] Reset settings - `DELETE /indexes/{indexUid}/settings`
- [ ] Get displayed attributes - `GET /indexes/{indexUid}/settings/displayed-attributes`
- [ ] Update displayed attributes - `PUT /indexes/{indexUid}/settings/displayed-attributes`
- [ ] Reset displayed attributes - `DELETE /indexes/{indexUid}/settings/displayed-attributes`
- [ ] Get searchable attributes - `GET /indexes/{indexUid}/settings/searchable-attributes`
- [ ] Update searchable attributes - `PUT /indexes/{indexUid}/settings/searchable-attributes`
- [ ] Reset searchable attributes - `DELETE /indexes/{indexUid}/settings/searchable-attributes`
- [ ] Get filterable attributes - `GET /indexes/{indexUid}/settings/filterable-attributes`
- [ ] Update filterable attributes - `PUT /indexes/{indexUid}/settings/filterable-attributes`
- [ ] Reset filterable attributes - `DELETE /indexes/{indexUid}/settings/filterable-attributes`
- [ ] Get sortable attributes - `GET /indexes/{indexUid}/settings/sortable-attributes`
- [ ] Update sortable attributes - `PUT /indexes/{indexUid}/settings/sortable-attributes`
- [ ] Reset sortable attributes - `DELETE /indexes/{indexUid}/settings/sortable-attributes`
- [ ] Get ranking rules - `GET /indexes/{indexUid}/settings/ranking-rules`
- [ ] Update ranking rules - `PUT /indexes/{indexUid}/settings/ranking-rules`
- [ ] Reset ranking rules - `DELETE /indexes/{indexUid}/settings/ranking-rules`
- [ ] Get stop words - `GET /indexes/{indexUid}/settings/stop-words`
- [ ] Update stop words - `PUT /indexes/{indexUid}/settings/stop-words`
- [ ] Reset stop words - `DELETE /indexes/{indexUid}/settings/stop-words`
- [ ] Get synonyms - `GET /indexes/{indexUid}/settings/synonyms`
- [ ] Update synonyms - `PUT /indexes/{indexUid}/settings/synonyms`
- [ ] Reset synonyms - `DELETE /indexes/{indexUid}/settings/synonyms`
- [ ] Get distinct attribute - `GET /indexes/{indexUid}/settings/distinct-attribute`
- [ ] Update distinct attribute - `PUT /indexes/{indexUid}/settings/distinct-attribute`
- [ ] Reset distinct attribute - `DELETE /indexes/{indexUid}/settings/distinct-attribute`
- [ ] Get typo tolerance - `GET /indexes/{indexUid}/settings/typo-tolerance`
- [ ] Update typo tolerance - `PATCH /indexes/{indexUid}/settings/typo-tolerance`
- [ ] Reset typo tolerance - `DELETE /indexes/{indexUid}/settings/typo-tolerance`
- [ ] Get faceting - `GET /indexes/{indexUid}/settings/faceting`
- [ ] Update faceting - `PATCH /indexes/{indexUid}/settings/faceting`
- [ ] Reset faceting - `DELETE /indexes/{indexUid}/settings/faceting`
- [ ] Get pagination - `GET /indexes/{indexUid}/settings/pagination`
- [ ] Update pagination - `PATCH /indexes/{indexUid}/settings/pagination`
- [ ] Reset pagination - `DELETE /indexes/{indexUid}/settings/pagination`
- [ ] Get dictionary - `GET /indexes/{indexUid}/settings/dictionary`
- [ ] Update dictionary - `PUT /indexes/{indexUid}/settings/dictionary`
- [ ] Reset dictionary - `DELETE /indexes/{indexUid}/settings/dictionary`
- [ ] Get separator tokens - `GET /indexes/{indexUid}/settings/separator-tokens`
- [ ] Update separator tokens - `PUT /indexes/{indexUid}/settings/separator-tokens`
- [ ] Reset separator tokens - `DELETE /indexes/{indexUid}/settings/separator-tokens`
- [ ] Get non-separator tokens - `GET /indexes/{indexUid}/settings/non-separator-tokens`
- [ ] Update non-separator tokens - `PUT /indexes/{indexUid}/settings/non-separator-tokens`
- [ ] Reset non-separator tokens - `DELETE /indexes/{indexUid}/settings/non-separator-tokens`
- [ ] Get localized attributes - `GET /indexes/{indexUid}/settings/localized-attributes`
- [ ] Update localized attributes - `PUT /indexes/{indexUid}/settings/localized-attributes`
- [ ] Reset localized attributes - `DELETE /indexes/{indexUid}/settings/localized-attributes`
- [ ] Get embedders - `GET /indexes/{indexUid}/settings/embedders`
- [ ] Update embedders - `PATCH /indexes/{indexUid}/settings/embedders`
- [ ] Reset embedders - `DELETE /indexes/{indexUid}/settings/embedders`
- [ ] Get proximity precision - `GET /indexes/{indexUid}/settings/proximity-precision`
- [ ] Update proximity precision - `PUT /indexes/{indexUid}/settings/proximity-precision`
- [ ] Reset proximity precision - `DELETE /indexes/{indexUid}/settings/proximity-precision`
- [ ] Get search cutoff ms - `GET /indexes/{indexUid}/settings/search-cutoff-ms`
- [ ] Update search cutoff ms - `PUT /indexes/{indexUid}/settings/search-cutoff-ms`
- [ ] Reset search cutoff ms - `DELETE /indexes/{indexUid}/settings/search-cutoff-ms`
- [ ] Get facet search setting - `GET /indexes/{indexUid}/settings/facet-search`
- [ ] Update facet search setting - `PUT /indexes/{indexUid}/settings/facet-search`
- [ ] Reset facet search setting - `DELETE /indexes/{indexUid}/settings/facet-search`
- [ ] Get prefix search - `GET /indexes/{indexUid}/settings/prefix-search`
- [ ] Update prefix search - `PUT /indexes/{indexUid}/settings/prefix-search`
- [ ] Reset prefix search - `DELETE /indexes/{indexUid}/settings/prefix-search`
- [ ] Get chat settings - `GET /indexes/{indexUid}/settings/chat`
- [ ] Update chat settings - `PUT /indexes/{indexUid}/settings/chat`
- [ ] Reset chat settings - `DELETE /indexes/{indexUid}/settings/chat`

## Tasks

- [ ] Get all tasks - `GET /tasks`

## Batches

- [ ] Get batches - `GET /batches`
- [ ] Get one batch - `GET /batches/{batchUid}`

## Keys

- [ ] Get API keys - `GET /keys`
- [ ] Create API key - `POST /keys`
- [ ] Get API key - `GET /keys/{uidOrKey}`
- [ ] Delete API key - `DELETE /keys/{uidOrKey}`
- [ ] Update API key - `PATCH /keys/{uidOrKey}`

## Stats

- [ ] Get stats of index - `GET /indexes/{indexUid}/stats`
- [ ] Get stats of all indexes - `GET /stats`
- [ ] Get prometheus metrics - `GET /metrics`

## Dumps & Snapshots

- [ ] Create a dump - `POST /dumps`
- [ ] Create a snapshot - `POST /snapshots`

## Experimental Features

- [ ] Get experimental features - `GET /experimental-features`
- [ ] Configure experimental features - `PATCH /experimental-features`

## Logs

- [ ] Retrieve logs - `POST /logs/stream`
- [ ] Stop retrieving logs - `DELETE /logs/stream`
- [ ] Update console log target - `POST /logs/stderr`

## Network

- [ ] Get network topology - `GET /network`
- [ ] Configure network - `PATCH /network`
