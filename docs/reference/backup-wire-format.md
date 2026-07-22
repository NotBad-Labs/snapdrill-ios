---
last_verified: 2026-07-22
layer: contract
freshness:
  max_age_days: 180
  decay_trigger: [backup_schema_change, dto_change, sqlite_version_change, compatibility_epoch]
---
# Backup Wire Format

> This document owns two deliberately separate facts: the immutable Profile ZIP v2 development
> fixture contract, and the ratified Release 1 Backup v3 wire contract. It records on-disk
> contracts, not current Swift type names.
>
> **Product rebaseline (2026-07-15):** Profile ZIP v2 remains frozen only so epoch-before rejection
> and historical fixtures stay explainable. PO-ratified D1-B selects a purpose-built SQLite
> `.snapdrillbackup` application document for Release 1. PO-ratified P3-A (2026-07-22) incorporates
> the exact v3 schema, defensive opening sequence, fixtures and compatibility rules below. Neither
> decision is a writer / reader implementation or merge authorization. The Profile-free semantic
> inventory and recovery lifetime are owned by
> [Local Library Data Contract](local-library-data-contract.md), not duplicated here.
>
> **Release safety inputs (2026-07-22):** S1-A, D4S-A and P2-B-A through P2-G-A constrain what a v3
> writer / reader must consume. Their product limits, semantic inventory, complete-operation prestate
> and mutation barrier remain owned by the Local Library Data Contract and are not duplicated here.

## Format Version

- Current live backup writer remains `BackupManifest.currentSchemaVersion == 2`.
- The ratified Release 1 external wire uses SQLite `user_version == 3`; it is not yet the live
  writer / reader merely because its contract is ratified.
- Backup schema versioning is independent from the SwiftData schema.
- Version `2` is the post-static-difficulty baseline: fixed `difficulty` is removed, and level /
  difficulty-like attributes are represented through dynamic dimensions and `categoryValueIds`.

### Release 1 Backup v3: exact ratified wire contract

**D1-B is ratified**: the user-controlled artifact is one purpose-built SQLite
`.snapdrillbackup` application document. It is not the live SwiftData store, a copied WAL database,
or a general ZIP. Ordinary ZIP extraction is not a Release 1 requirement. Files, AirDrop and the
system share sheet still treat the result as one portable document.

**P3-A is ratified (PO, 2026-07-22):** this document incorporates the immutable
[Backup v3 contract candidate](backup-wire-v3/backup-wire-v3-candidate.md) and its evidence package
with these exact identities:

- contract candidate SHA-256:
  `0fa115bfedc851a3cbda36d7add21d7921a5342c1367c1481dc57ed9a3398575`;
- package [manifest](backup-wire-v3/manifest.json) SHA-256:
  `b4a595a7e14f48272474c81de1536652f2be25a4e6c1edf862004f8f5138669d`;
- manifest-framed review-input SHA-256:
  `3a32f0f33a8d3aeb4446e88d724f717eda276ba0a518f86e73e12735259cc4aa`;
- independent [review result](backup-wire-v3/independent-review-result.json) SHA-256:
  `68a5c4cd38ac7a3ee910e0d45e24bb46522ea24ececfda3792becefbb82f0e4f`
  (`PASS`, zero findings).

The candidate file's own "not yet ratified" status is immutable freeze-time provenance; this owning
document controls its current lifecycle. The package remains subordinate evidence, never a second
product or lifecycle authority. Any byte change that breaks one of these identities requires a new
review and PO ratification. Any incompatible wire change requires a later `user_version`; v3 cannot
be reinterpreted in place.

P3-A fixes the following irreversible wire details through the incorporated candidate and package:

- versioned DDL, a SnapDrill-specific `application_id`, `user_version`, exact allowed objects and
  migration / rejection rules;
- a Profile-free inventory containing every DATA-1 record, required relationship and main / answer
  image BLOB, with unique IDs, non-null ownership, foreign keys and per-record digests;
- a hostile-file opening sequence that first copies the picked file into a fresh quarantine root,
  rejects symlink/sidecar smuggling, opens read-only/no-follow, disables trusted schema and executable
  schema features, reduces runtime/mmap limits, and applies authorizer plus progress deadline before
  semantic traversal;
- exact schema allowlisting, integrity/cell/foreign-key checks, duplicate/dangling-reference rejection,
  image decode/privacy validation and all-or-nothing semantic closure before active-library mutation;
- incremental `sqlite3_blob` read/write under the <200 MiB process-memory NFR; no image set or whole
  database may be materialized as one `Data`;
- writer-reader capacity closure for every library the same product supports creating, consuming
  S1-A from the Local Library Data Contract rather than creating wire-local product limits;
- transaction/finalization rules proving the exported artifact is exactly one closed file with no
  required WAL/journal sidecar, plus semantic golden fixtures, adversarial corpus and a documented
  standard-SQLite extraction recipe.

P3-A becomes effective only when this owning-document change is merged into `develop`. It does not
authorize a production writer / reader, Profile-free runtime, restore switch, legacy retirement,
upload or release. Each implementation slice and merge still requires its own current admission,
validation and PO merge authorization.

Byte-for-byte SQLite determinism is not required. The schema and semantic fixtures are. D3-B's
`missing-at-snapshot` state belongs only to an internal recovery-only artifact and must never appear
as an accepted substitute for a complete external v3 backup.

D4S-A classifies external `.snapdrillbackup` generation as a complete operation. The writer may
continue after its immutable source snapshot is detached / finalized without holding active-library
mutation admission closed. Settings JSON / CSV and selected PDF / CSV remain partial exports and do
not inherit the complete-operation barrier. Exact lifecycle semantics remain in the Local Library
Data Contract; this paragraph changes no v2 or v3 wire grammar.

The former general-ZIP / ZIP32 / ZIP64 explorations are superseded by D1-B. ZIPFoundation remains
only in the epoch-before v2 implementation until a separately authorized retirement slice; its
presence cannot influence the v3 grammar.

## Development Wire v2: ZIP Entries

Every backup archive contains these fixed top-level entries:

| Entry | Required | Purpose |
|---|---:|---|
| `manifest.json` | Yes | Backup metadata and schema gate |
| `data.json` | Yes | Profile data, archive items, dimensions, and category values |
| `profiles/<profileId>/...` image paths | Optional | Image bytes referenced by `imagePath` / `answerImagePath` |

The JSON encoder uses ISO-8601 dates plus pretty-printed sorted keys. Consumers must not depend on
whitespace, but tests keep golden fixtures to detect accidental key or shape drift.

## `manifest.json`

`manifest.json` encodes `BackupManifest`:

| Key | Type | Contract |
|---|---|---|
| `schemaVersion` | Int | Must be `2` for the current writer |
| `createdAt` | ISO-8601 string | Backup creation timestamp |
| `appVersion` | String | App marketing version at export time |
| `totalItemCount` | Int | Total archive items across all profiles |
| `profileCount` | Int | Number of profiles in `data.json` |
| `profileNames` | `[String]` | Human-readable profile names |

## `data.json`

`data.json` encodes `BackupPayload` with top-level key `profiles`.

Each profile uses this stable shape:

| Key | Type | Contract |
|---|---|---|
| `profileName` | String | Human-readable profile name |
| `profileId` | UUID string | Profile identity used for image paths and restore |
| `reviewItems` | `[ArchiveItemBackupDTO]` | **Stable external key. Do not rename to `archiveItems` without a backup schema version bump and compatibility plan.** |
| `dimensions` | `[CategoryDimensionBackupDTO]` | Dynamic field definitions |
| `categoryValues` | `[CategoryValueBackupDTO]` | Dynamic field values |

The `reviewItems` key intentionally preserves the pre-`ArchiveItemModel` wire name. It is a backup
compatibility contract, not a product-positioning term.

Each item contains:

- identity and content: `id`, `content`, `imagePath`, `answerText`, `answerImagePath`
- timestamps: `createdAt`, `lastReviewedAt`, `nextReviewAt`
- SM-2 state: `easeFactor`, `interval`, `repetitions`
- dynamic taxonomy links: `categoryValueIds`

Nil optional fields are omitted by the current JSON encoder. Empty profiles still encode
`reviewItems: []`, `dimensions: []`, and `categoryValues: []`.

## Test Contract

Golden fixtures live under:

`Packages/SnapDrillData/Tests/SnapDrillDataTests/Fixtures/BackupWireV2/`

The fixture tests must assert:

- `schemaVersion` remains `2`;
- `reviewItems` is present and `archiveItems` is absent;
- dynamic dimension keys and category value IDs survive decode;
- empty profile payloads keep the empty `reviewItems` key.

Changing any key in this document is a wire-format change. It requires an explicit schema-version
decision before implementation.
