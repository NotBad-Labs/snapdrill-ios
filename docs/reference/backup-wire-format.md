---
last_verified: 2026-07-14
layer: contract
freshness:
  max_age_days: 180
  decay_trigger: [backup_schema_change, dto_change, zipfoundation_update]
---
# Backup Wire Format

> This document is the stable contract for SnapDrill `.zip` backup files. It records the on-disk
> wire shape, not the current Swift type names. Runtime DTO tests and golden fixtures must fail if
> this contract drifts unintentionally.
>
> **Product rebaseline (2026-07-14):** this page freezes the currently implemented development
> wire v2 and its fixtures; it does not authorize a user-visible Profile model or define the final
> Release 1 wire. Product Constitution v1 requires one visible library, and
> [Release 1 Product Contract](release-1-contract.md) DATA-1 requires a Profile-free external wire
> plus an epoch compatibility promise. Do not mutate v2 or implement a replacement format from this
> document alone. The Data / Security DRI must first replace the exploration below with one reviewed,
> capacity-closed Data Contract; a separately authorized implementation must update schema, writer,
> reader and golden fixtures together.

## Format Version

- Current backup schema version: `BackupManifest.currentSchemaVersion == 2`.
- Backup schema versioning is independent from the SwiftData schema.
- Version `2` is the post-static-difficulty baseline: fixed `difficulty` is removed, and level /
  difficulty-like attributes are represented through dynamic dimensions and `categoryValueIds`.

### Profile-free wire Data Contract scope

DATA-1 does not select ZIP32, ZIP64, a parser or numeric resource limits. Before changing writer,
reader or fixtures, the Data / Security DRI must freeze:

- the Profile-free payload fields and the exact set of content-bearing data included by DATA-1;
- archive / container grammar, required and optional entries, path grammar, duplicate / unknown
  policy, encryption declaration and schema evolution rules;
- writer-reader self-compatibility, ID / reference closure, image decode / privacy handling and
  actual-byte / pixel / count resource defenses;
- a capacity proof that every library the product supports creating can be exported and restored;
- matching golden fixtures, migration / conversion fixtures and adversarial tests in the same slice.

One explored design narrows the future wire to single-disk ZIP32 with an exact regular-file set and independent
bounded central-directory validation. It is viable only if the capacity proof shows ZIP32 and its
entry limits can cover every supported library. Otherwise the DRI must select ZIP64, segmentation or
another bounded format and review that grammar. Current code's 50 MiB single-entry and 1 GiB image
restore limits are implementation facts, not approved product limits; a total cap that rejects a
library SnapDrill can create is invalid. Any formal writer success must fully round-trip through the
matching reader.

The narrowed ZIP32 exploration makes a bounded structural validator feasible. ZIPFoundation 0.9.20
public iteration cannot by itself prove archive completeness: a local probe retained an EOCD count
of two, corrupted the second central-directory signature, and observed successful archive
initialization followed by only one public entry. This
is shaping evidence, not permission to add a custom parser or fork the dependency; that engineering
choice requires its own reviewed D-A DoR under DATA-1.

As verified on 2026-07-13, [0.9.20 remains the latest official release](https://github.com/weichsel/ZIPFoundation/releases/tag/0.9.20),
and the official [`development` branch iterator](https://github.com/weichsel/ZIPFoundation/blob/development/Sources/ZIPFoundation/Archive.swift)
retains the same non-throwing early-`nil` behavior. A dependency update invalidates this evidence and
must trigger a fresh upstream/API review before retaining a custom validator.

If the Data Contract later selects a narrow validator, ZIPFoundation remains the extraction implementation only after
preflight. Either parser rejecting, extraction/CRC failing, or the two layers disagreeing on entry
paths/counts/sizes must reject the whole archive before any library or recovery mutation.

## Zip Entries

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
