# Diogenes

> "Diogenes (philosophical/legendary) — famously wandered with a lantern in daylight searching for an honest man" 
>
> -- Claude --

You might not be as lost as Diogenes, but it's always good to have a lantern to look for documents, this one is called 
Meilisearch and Diogenes is your sans-io Gleam library that wraps all the HTTP calls for you.

The library handles request making and response parsing. Your app handles API calls and error handling the way you like.

The library provides types for indexes and tasks. Your app provides decoders/encoders for your Meilisearch documents.

## Example
```gleam
import diogenes
import gleam/httpc
import gleam/io
import gleam/option
import gleam/string

pub fn main() -> Nil {
  let client =
    diogenes.new_client(
      "http://127.0.0.1:7700",
      option.Some("123456789123456789"),
    )
  let #(req, parser) = diogenes.health(client)
  case httpc.send(req) {
    Ok(resp) -> {
      case parser(resp) {
        Ok(_) -> io.println("Response: OK")
        Error(_) -> io.println("Error")
      }
    }
    Error(error) -> io.println("Error: " <> string.inspect(error))
  }
}
```

[![Package Version](https://img.shields.io/hexpm/v/diogenes)](https://hex.pm/packages/diogenes)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/diogenes/)

Further documentation can be found at <https://hexdocs.pm/diogenes>.

## Features Development

### 1. System
- [ ] Health check

### 2. Indexes
- [ ] Create index
- [ ] Get index
- [ ] Delete index

### 3. Settings
- [ ] Get/update embedders
- [ ] Get/update searchable attributes
- [ ] Get/update filterable attributes

### 4. Tasks
- [ ] Wait for task completion
- [ ] Get task by id

### 5. Documents
- [ ] Add or replace documents
- [ ] Delete all documents
- [ ] Delete document by id

### 6. Search
- [ ] Semantic search (vector)
- [ ] Hybrid search (semantic + keyword)
- [ ] Basic keyword search
- [ ] Filter
- [ ] Pagination

### Backlog
- [ ] Add or update documents (partial)
- [ ] Get document by id
- [ ] List documents
- [ ] Sort
- [ ] Faceted search
- [ ] Highlight matches
- [ ] Crop matches
- [ ] Multi-index search (federated)
- [ ] Get/update ranking rules
- [ ] Get/update sortable attributes
- [ ] Get/update stop words
- [ ] Get/update synonyms
- [ ] Get/update typo tolerance
- [ ] Get/update faceting
- [ ] Get/update pagination defaults
- [ ] Get/update distinct attribute
- [ ] Reset settings
- [ ] List indexes
- [ ] Update index primary key
- [ ] List tasks
- [ ] Cancel tasks
- [ ] Delete tasks
- [ ] API key management
- [ ] Get version
- [ ] Get stats

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
