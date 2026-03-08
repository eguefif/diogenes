# Diogenes

> "Diogenes (philosophical/legendary) — famously wandered with a lantern in daylight searching for an honest man" 
>
> -- Claude --

You might not be as lost as Diogenes, but it's always good to have a lantern to look for documents, this one is called 
Meilisearch and Diogenes is your Gleam library that wraps all the HTTP calls for you.

## Example
```gleam
import diogenes
import diogenes/health
import diogenes/index
import gleam/httpc
import gleam/io
import gleam/option
import gleam/string
import sansio/health as sansio_health

pub fn main() -> Nil {
  let client = diogenes.new_client("http://127.0.0.1:7700", option.None)

  // Using the IO library

  // Test health
  let _ = health.get_health(client)

  // Test create index

  let _ = index.create_index(client, "test_index6", option.Some("id"))

  // Using the sans-io library

  // Test health
  let #(request, parser) = sansio_health.get_health(client)
  case httpc.send(request) {
    Ok(response) -> {
      case parser(response.status, response.body) {
        Ok(response) -> io.println("Response ok: " <> string.inspect(response))
        Error(err) -> io.println("Response error: " <> string.inspect(err))
      }
    }
    Error(err) -> io.println("Httpc error: " <> string.inspect(err))
  }
}

```

## Architecture

The library is composed by two components:
- A sans-io core library that will build Request and return parsers to handle Meilisearch Response
- A IO layer that uses httpc to query the database

You can use the sans-io library as you want if you want to handle your IO. Note that the sans-io library will handle some http status code as it is part of the Meilisearch response.

As an example, when you use `create_index()`, Meilisearch can return a status code 401 when an error occured. This error will be parsed and returned
by the sans-io library in a MeilisearchError record.

[![Package Version](https://img.shields.io/hexpm/v/diogenes)](https://hex.pm/packages/diogenes)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/diogenes/)

Further documentation can be found at <https://hexdocs.pm/diogenes>.

## Features Development

- [ ] For HTTPC and dynamic Error, should we transform them into our own error or the documentation
        should mention where to find the error type?

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
