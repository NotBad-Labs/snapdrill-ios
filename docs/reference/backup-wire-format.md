---
last_verified: 2026-07-11
layer: contract
freshness:
  max_age_days: 180
  decay_trigger: [backup_schema_change, dto_change]
---
# Backup Wire Format

> Stable on-disk contract for SnapDrill `.zip` backups. Runtime DTO tests and golden fixtures must
> fail if this shape drifts unintentionally.

## Format Version

- Current schema: `BackupManifest.currentSchemaVersion == 3`.
- Backup schema versioning is independent from the SwiftData schema.
- Version 3 is the 2026-07-11 single-library rebaseline. It deliberately does not read or migrate
  the retired Profile-based v1/v2 wire because the product had no users or distributed backups.
- Starting with the first external user build, future changes require an explicit compatibility
  decision and schema increment.

## Zip Entries

| Entry | Required | Purpose |
|---|---:|---|
| `manifest.json` | Yes | Backup metadata and schema gate |
| `data.json` | Yes | Single-library items, dimensions, and category values |
| `images/...` | Conditional | Required for every non-nil `imagePath` / `answerImagePath`; absent when payload has no images |

Image entries must be safe relative paths rooted at `images/`. Absolute paths, backslashes, empty
components, `.` and `..` are invalid. Restore also enforces a 50MB single-entry limit and a 1GB
total based on actual extracted image bytes. User-created backups fail rather than silently omit a
referenced image, and restore rejects a payload whose referenced image entry is absent.

## `manifest.json`

| Key | Type | Contract |
|---|---|---|
| `schemaVersion` | Int | Must equal `3` for the current reader/writer |
| `createdAt` | ISO-8601 string | Backup creation timestamp |
| `appVersion` | String | App marketing version at export time |
| `totalItemCount` | Int | Total archive items in the library |

No Profile count, name, or identity is encoded.

## `data.json`

`BackupPayload` directly encodes these top-level keys:

| Key | Type | Contract |
|---|---|---|
| `reviewItems` | `[ArchiveItemBackupDTO]` | Stable external key; do not rename without a schema decision |
| `dimensions` | `[CategoryDimensionBackupDTO]` | Dynamic field definitions |
| `categoryValues` | `[CategoryValueBackupDTO]` | Dynamic field values |

Each item contains identity/content, image paths, timestamps, SM-2 state and
`categoryValueIds`. Nil optional fields are omitted; empty arrays remain encoded.

## Test Contract

Golden fixtures:

`Packages/SnapDrillData/Tests/SnapDrillDataTests/Fixtures/BackupWireV3/`

Tests assert schema 3, direct top-level arrays, absence of Profile metadata, field round-trip,
unsafe image-path rejection and explicit rejection of retired schemas.
