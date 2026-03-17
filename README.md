# Diogenes

> "Diogenes  — famously wandered with a lantern in daylight searching for an honest man." 
>
> -- Claude --

You might not be as lost as Diogenes, but it's always good to have a lantern to look for documents, this one is called 
Meilisearch and Diogenes is your Gleam library that wraps all the HTTP calls for you.

## Progress

| Section | Progress |
|---|---|
| Index | 100% |
| Documents | 85% |
| Search | 0% |
| Multi-search | 0% |
| Facet search | 0% |
| Similar document search | 0% |
| Charts | 0% |
| Tasks | 0% |
| Batches | 0% |
| Keys | 0% |
| Settings | 25% |
| Management | 0% |

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


## Development

If you want to contribute, there is a [test project](https://github.com/eguefif/diogenes_test) that setup a meilisearch docker. Nothing fancy, The tester will only run as many requests as it needs for all the functions in the library.
