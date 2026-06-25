---
last_verified: 2026-06-25
layer: contract
freshness:
  max_age_days: 180
  decay_trigger: [backup_schema_change, dto_change]
---
# Backup Wire Format

> This document is the stable contract for SnapDrill `.zip` backup files. It records the on-disk
> wire shape, not the current Swift type names. Runtime DTO tests and golden fixtures must fail if
> this contract drifts unintentionally.

## Format Version

- Current backup schema version: `BackupManifest.currentSchemaVersion == 2`.
- Backup schema versioning is independent from the SwiftData schema.
- Version `2` is the post-static-difficulty baseline: fixed `difficulty` is removed, and level /
  difficulty-like attributes are represented through dynamic dimensions and `categoryValueIds`.

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
