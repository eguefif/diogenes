//// Functions for creating Meilisearch dumps and snapshots.
////
//// Dumps export the full database to a `.dump` file that can be used to
//// restore or migrate a Meilisearch instance. Snapshots create binary
//// backups of the database for fast recovery.
////
//// ## TODO
////
//// - [ ] Create a dump - `POST /dumps`
//// - [ ] Create a snapshot - `POST /snapshots`

import diogenes.{type Client, type Error, type MeilisearchResponse}
import internal/http_tooling.{send_request}

/// Triggers the creation of a database dump.
///
/// The dump is saved to the path configured via `--dump-dir`. This is an
/// asynchronous operation that returns a task.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/dump)
pub fn create_dump(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}

/// Triggers the creation of a database snapshot.
///
/// Snapshots are binary copies of the database and can be restored faster
/// than dumps, but are not portable across versions. This is an asynchronous
/// operation that returns a task.
///
/// [Meilisearch documentation](https://www.meilisearch.com/docs/reference/api/snapshot)
pub fn create_snapshot(
  client: Client,
) -> Result(MeilisearchResponse(a), Error) {
  let _ = client
  let _ = send_request
  todo
}
