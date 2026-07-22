# SnapDrill Backup v3 Contract Candidate

Status: exact contract candidate for adversarial review. The package is not yet ratified,
effective, or an implementation authorization.

Baseline: `origin/develop@a3378bca81bae0711818026407b158697cb8cf94`.

## 1. Fixed family identity

- Extension: `.snapdrillbackup`
- Exported UTType: `com.snapdrill.global.backup`, whose Info property-list declaration explicitly
  lists all three conformances `public.data`, `public.content`, and `public.database`, with the sole
  filename-extension tag `snapdrillbackup` and a localizable `SnapDrill Backup` description.
- Container: one closed SQLite application file, not a live SwiftData store and not ZIP.
- SQLite `application_id`: `0x2A2829A0` (`707275168`).
- SQLite `user_version`: `3`.
- Page size: 4096 bytes.
- Text encoding: UTF-8.
- Final journal mode: DELETE, with no required `-wal`, `-shm`, or journal sidecar.

`0x2A2829A0` is the positive 31-bit value obtained by clearing the high bit of the first
32 bits of `SHA-256("com.snapdrill.global:.snapdrillbackup")`. It does not appear in SQLite's
official trunk `magic.txt` application-ID list checked on 2026-07-18 or in an exact-hex repository
search. The earlier readable `0x5344424B` proposal is rejected: `SDBK` is already a widely used
Microsoft XACT sound-bank signature and its uniqueness claim was too strong. SQLite has no
collision-proof central allocation service; the derivation and registry checks are recorded as
dated evidence, not an absolute global uniqueness claim.

The application ID identifies the SnapDrill backup family and never changes. Every incompatible
schema increments `user_version`. Apple does not define `public.database` as automatically
conforming to either `public.data` or `public.content`; all three are deliberate. The bundle
declaration is the source for the multi-parent hierarchy. The Swift accessor resolves that exact
declared identifier and fails closed in tests/startup if it is absent, dynamically synthesized,
has a different preferred extension, or lacks any of the three conformances; it does not treat a
single-parent `UTType(exportedAs:conformingTo:)` construction as proof that the bundle declaration
matches. Declaring the type does not itself authorize an open-in-place document browser or an
additional restore entry point. Filename extension and UTType are discovery metadata, not security
evidence; the reader still requires the byte/header/schema/semantic checks below.

## 2. Proposed exact DDL

The effective S1-A product-size policy is embedded as the v3 schema image so the schema can be
tested:

- `content` and `answer_text`: at most 1 MiB of UTF-8 each.
- taxonomy names: at most 1024 UTF-8 bytes.
- SF Symbol names: at most 256 UTF-8 bytes.
- one JPEG: at most 50 MiB, with width and height each at most 2000 pixels.
- no total item, image, or database-size cap other than checked integer range and available storage.

The numeric ownership remains in the Local Library Data Contract. These literals are the frozen v3
encoding of that authority at this candidate's baseline; changing one requires a new wire version,
not an in-place reinterpretation of v3.

```sql
PRAGMA application_id = 707275168; -- 0x2A2829A0
PRAGMA user_version = 3;

CREATE TABLE backup_root (
    singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
    artifact_kind TEXT NOT NULL CHECK(artifact_kind = 'external-complete'),
    wire_version INTEGER NOT NULL CHECK(wire_version = 3),
    created_at_ms INTEGER NOT NULL
        CHECK(created_at_ms BETWEEN -1000000000000000 AND 1000000000000000),
    writer_marketing_version TEXT NOT NULL
        CHECK(length(CAST(writer_marketing_version AS BLOB)) BETWEEN 1 AND 128),
    writer_build TEXT NOT NULL
        CHECK(length(CAST(writer_build AS BLOB)) BETWEEN 1 AND 64),
    digest_algorithm TEXT NOT NULL CHECK(digest_algorithm = 'sha256'),
    item_count INTEGER NOT NULL CHECK(item_count >= 0),
    dimension_count INTEGER NOT NULL CHECK(dimension_count >= 0),
    value_count INTEGER NOT NULL CHECK(value_count >= 0),
    item_value_count INTEGER NOT NULL CHECK(item_value_count >= 0),
    image_count INTEGER NOT NULL CHECK(image_count >= 0),
    image_byte_count INTEGER NOT NULL CHECK(image_byte_count >= 0),
    inventory_sha256 BLOB NOT NULL CHECK(length(inventory_sha256) = 32)
) STRICT, WITHOUT ROWID;

CREATE TABLE category_dimension (
    id BLOB PRIMARY KEY CHECK(length(id) = 16),
    name TEXT NOT NULL CHECK(length(CAST(name AS BLOB)) BETWEEN 1 AND 1024),
    is_multi_value INTEGER NOT NULL CHECK(is_multi_value IN (0, 1)),
    is_built_in INTEGER NOT NULL CHECK(is_built_in IN (0, 1)),
    system_key TEXT,
    sort_order INTEGER NOT NULL,
    icon TEXT NOT NULL
        CHECK(
            length(CAST(icon AS BLOB)) BETWEEN 1 AND 256
            AND instr(icon, char(0)) = 0
            AND icon NOT GLOB '*[^a-z0-9.]*'
        ),
    record_sha256 BLOB NOT NULL CHECK(length(record_sha256) = 32),
    CHECK(
        (is_built_in = 0 AND system_key IS NULL)
        OR
        (
            is_built_in = 1
            AND system_key IS NOT NULL
            AND (
                (system_key = 'tag' AND is_multi_value = 1)
                OR
                (system_key IN ('category', 'source', 'level') AND is_multi_value = 0)
            )
        )
    )
) STRICT, WITHOUT ROWID;

CREATE UNIQUE INDEX ux_category_dimension_name
    ON category_dimension(name);
CREATE UNIQUE INDEX ux_category_dimension_system_key
    ON category_dimension(system_key)
    WHERE system_key IS NOT NULL;

CREATE TABLE category_value (
    id BLOB PRIMARY KEY CHECK(length(id) = 16),
    dimension_id BLOB NOT NULL
        REFERENCES category_dimension(id) ON DELETE RESTRICT,
    name TEXT NOT NULL CHECK(length(CAST(name AS BLOB)) BETWEEN 1 AND 1024),
    icon TEXT NOT NULL
        CHECK(
            length(CAST(icon AS BLOB)) BETWEEN 1 AND 256
            AND instr(icon, char(0)) = 0
            AND icon NOT GLOB '*[^a-z0-9.]*'
        ),
    color_hex TEXT NOT NULL
        CHECK(
            length(CAST(color_hex AS BLOB)) = 7
            AND color_hex GLOB
                '#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
            AND color_hex = upper(color_hex)
        ),
    sort_order INTEGER NOT NULL,
    created_at_ms INTEGER NOT NULL
        CHECK(created_at_ms BETWEEN -1000000000000000 AND 1000000000000000),
    record_sha256 BLOB NOT NULL CHECK(length(record_sha256) = 32)
) STRICT, WITHOUT ROWID;

CREATE UNIQUE INDEX ux_category_value_dimension_name
    ON category_value(dimension_id, name);

CREATE TABLE library_item (
    id BLOB PRIMARY KEY CHECK(length(id) = 16),
    content TEXT
        CHECK(
            content IS NULL
            OR length(CAST(content AS BLOB)) <= 1048576
        ),
    created_at_ms INTEGER NOT NULL
        CHECK(created_at_ms BETWEEN -1000000000000000 AND 1000000000000000),
    last_reviewed_at_ms INTEGER
        CHECK(
            last_reviewed_at_ms IS NULL
            OR last_reviewed_at_ms BETWEEN -1000000000000000 AND 1000000000000000
        ),
    next_review_at_ms INTEGER
        CHECK(
            next_review_at_ms IS NULL
            OR next_review_at_ms BETWEEN -1000000000000000 AND 1000000000000000
        ),
    ease_factor REAL NOT NULL
        CHECK(
            ease_factor BETWEEN
                -1.7976931348623157e308 AND 1.7976931348623157e308
        ),
    interval_days INTEGER NOT NULL CHECK(interval_days BETWEEN 0 AND 365),
    repetitions INTEGER NOT NULL CHECK(repetitions >= 0),
    answer_text TEXT
        CHECK(
            answer_text IS NULL
            OR length(CAST(answer_text AS BLOB)) <= 1048576
        ),
    record_sha256 BLOB NOT NULL CHECK(length(record_sha256) = 32)
) STRICT, WITHOUT ROWID;

CREATE TABLE item_category_value (
    item_id BLOB NOT NULL
        REFERENCES library_item(id) ON DELETE RESTRICT,
    value_id BLOB NOT NULL
        REFERENCES category_value(id) ON DELETE RESTRICT,
    record_sha256 BLOB NOT NULL CHECK(length(record_sha256) = 32),
    PRIMARY KEY(item_id, value_id)
) STRICT, WITHOUT ROWID;

CREATE TABLE item_image (
    blob_id INTEGER PRIMARY KEY CHECK(blob_id > 0),
    item_id BLOB NOT NULL
        REFERENCES library_item(id) ON DELETE RESTRICT,
    role INTEGER NOT NULL CHECK(role IN (0, 1)),
    media_type TEXT NOT NULL CHECK(media_type = 'image/jpeg'),
    pixel_width INTEGER NOT NULL CHECK(pixel_width BETWEEN 1 AND 2000),
    pixel_height INTEGER NOT NULL CHECK(pixel_height BETWEEN 1 AND 2000),
    byte_count INTEGER NOT NULL CHECK(byte_count BETWEEN 1 AND 52428800),
    content_sha256 BLOB NOT NULL CHECK(length(content_sha256) = 32),
    record_sha256 BLOB NOT NULL CHECK(length(record_sha256) = 32),
    jpeg_bytes BLOB NOT NULL CHECK(length(jpeg_bytes) = byte_count)
) STRICT;

CREATE UNIQUE INDEX ux_item_image_item_role
    ON item_image(item_id, role);
```

The allowlist is exactly six tables and four explicit indexes. No auto-index, view, trigger,
virtual table, `sqlite_sequence`, or `sqlite_stat*` object is accepted. `item_image` alone keeps a
rowid because incremental `sqlite3_blob` I/O cannot address `WITHOUT ROWID` tables. Image role `0`
means `main`; role `1` means `answer`. The BLOB is the last column so metadata and its record digest
can be traversed without walking the BLOB overflow chain.

## 3. Semantic closure beyond DDL

Before active-library mutation, the reader proves all of the following. The byte-exact schema
manifest proves only which DDL was declared; SQLite does not evaluate `CHECK` constraints on
`SELECT`. The hostile reader therefore re-proves every `CHECK` predicate below from typed row
values, including root constants, byte lengths/ranges, finite doubles, built-in grammar, timestamp
bounds, icon/color grammar, image constants and digest lengths. Bool and image-role integers outside
their exact domains reject and are never coerced into canonical frames.

1. `backup_root` has exactly one row, and every count and the checked image-byte sum equals the
   traversed inventory. Counts are never allocation hints. Traversal uses overflow-reporting Int64
   arithmetic and rejects on any count or byte-sum overflow; it never relies on SQL `SUM` for
   adversarial values.
2. Built-in dimensions contain exactly one each of `category`, `source`, `level`, and `tag`, and
   no other built-in key. Custom dimensions have `system_key = NULL`. Missing built-ins reject the
   artifact; the reader never synthesizes or repairs them during restore.
3. Every UUID is exactly the 16 raw bytes corresponding to Swift `uuid_t` / the canonical UUID
   byte order. Variant and version bits are not additionally constrained. Primary keys and unique
   indexes close duplicate identities and exact, byte-sensitive names. The hostile reader also
   sorts the selected typed rows and re-proves every primary and unique key before foreign-key,
   count or digest validation; declared DDL is not accepted as proof that crafted b-tree rows are
   unique.
4. `foreign_key_check` is empty. Every item/value join is unique and closed.
5. Under effective M1-A, every dimension with `is_multi_value = 0` has at most one linked value per
   item. The production editor blocks a multi-to-single transition while any item violates that
   invariant before the v3 writer can ship; the writer never prunes links.
6. Every item has at least one of nonempty UTF-8 `content` or exactly one role-`0` main image;
   having both is valid. Empty `content` remains byte-distinct from NULL but is valid only when a
   main image closes the item. Empty `answer_text` remains byte-distinct from NULL. A role-`1`
   answer image is optional and independent of `answer_text`; the unique `(item_id, role)` index
   permits at most one main and one answer image per item.
7. Every `jpeg_bytes` value is the normalized v3 wire JPEG. It starts with exact bytes
   `FF D8 FF E0 00 10 4A 46 49 46 00 01 02 00 00 01 00 01 00 00` (SOI plus JFIF 1.02,
   unspecified 1:1 density, no thumbnail) and ends with its only EOI `FF D9` at `byte_count`.
   Prefixes, trailers, concatenated JPEGs, extra APP0, APP1...APP15, COM, embedded thumbnails,
   EXIF/TIFF/GPS/MakerNote, XMP, IPTC/8BIM, ICC, MPF, Adobe and unknown application payloads are
   invalid.
8. Outside entropy-coded scans, the JPEG marker allowlist is SOI, the fixed APP0 above, DQT, DHT,
   optional DRI, exactly one 8-bit SOF0, one or more SOS, and EOI. Inside a scan, `FF`
   introduces only byte stuffing, RST0...RST7, or a valid transition to the next allowed marker.
   The frame has either component ID `1`, or ordered component IDs `1,2,3`; dimensions are
   `1...2000`, match the row and match a forced full-raster decode. A bounded marker parser permits
   at most three scans. Component and quantization-table definitions cannot be duplicated. A Huffman
   table ID cannot be duplicated inside one DHT segment, but a later DHT segment may replace an
   active table between scans only after the prior definition has been referenced; each SOS may
   reference only tables defined before that scan, and every final active definition is referenced
   before EOI. Every component's quantization table exists before its scan and every component
   appears exactly once. SOF1/SOF2 and all other frame classes are invalid; accepting progressive
   frames would require proving complete coefficient coverage that ImageIO does not expose. An RST
   marker requires a prior nonzero DRI and each scan's restart
   sequence begins at RST0 and increments modulo eight. The parser also proves that all
   table/component references and segment/scan/EOF structure close; independently, ImageIO reports
   JPEG, complete source/index status, image count one, absent-or-1 orientation and a successful
   full decode. ImageIO property keys do not expand the raw marker allowlist.
9. Every image byte stream matches `byte_count` and `content_sha256`. Every canonical row matches
   its `record_sha256`. The root row's canonical metadata and all ordered row digests match
   `inventory_sha256`.
10. Before calling any coercive `sqlite3_column_*` accessor, decoding UTF-8, allocating from a
    value, or hashing a row, the reader requires the exact logical SQLite storage class reported by
    `sqlite3_column_type` for every selected cell. DDL affinity and `STRICT` are not accepted as
    proof for a directly crafted hostile file:
    - `backup_root`: the singleton, version, timestamp and six count/byte-count columns are
      `SQLITE_INTEGER`; the four protocol/version labels are `SQLITE_TEXT`; the inventory digest is
      `SQLITE_BLOB`;
    - `category_dimension`: IDs/digests are `SQLITE_BLOB`; name/icon are `SQLITE_TEXT`; flags/order
      are `SQLITE_INTEGER`; `system_key` is exactly `SQLITE_NULL` or `SQLITE_TEXT`;
    - `category_value`: IDs/digests are `SQLITE_BLOB`; name/icon/color are `SQLITE_TEXT`; order/time
      are `SQLITE_INTEGER`;
    - `library_item`: ID/digest are `SQLITE_BLOB`; content/answer are exactly `SQLITE_NULL` or
      `SQLITE_TEXT`; timestamps are `SQLITE_INTEGER` or the declared nullable
      `SQLITE_NULL`; `ease_factor` is `SQLITE_FLOAT`; interval/repetitions are `SQLITE_INTEGER`;
    - `item_category_value`: all three cells are `SQLITE_BLOB`;
    - `item_image`: `blob_id`, role, dimensions and byte count are `SQLITE_INTEGER`; item ID,
      both digests and JPEG bytes are `SQLITE_BLOB`; media type is `SQLITE_TEXT`.
    Any other observable storage class rejects before conversion. Raw on-disk serial type is not
    compatibility identity: SQLite may encode an exactly integral REAL with an INTEGER serial type
    and expose it again as `SQLITE_FLOAT` after REAL affinity. That documented optimization is valid
    and is not a wrong-class case. The adversarial harness generates every wrong logical
    class/table/column combination, including values a coercive accessor could otherwise make look
    valid.
11. User display text is valid UTF-8 and is preserved byte-for-byte without Unicode normalization.
    Embedded NUL is permitted in `content`, `answer_text`, dimension names and value names and is
    counted as UTF-8 bytes. `writer_marketing_version` and `writer_build` are opaque informational
    UTF-8 labels, not protocol identity or numeric-version fields; they likewise permit embedded NUL
    and are byte-preserved. For every TEXT column the reader first requires `SQLITE_TEXT`, obtains
    `sqlite3_column_bytes` and copies exactly that many bytes from `sqlite3_column_text`; it never
    calls `strlen` or constructs a C-string-terminated value. UTF-8 decoding must succeed without
    replacement and re-encoding must reproduce the same bytes. The writer uses
    `sqlite3_bind_text64` with the explicit UTF-8 byte count and never the `-1` C-string sentinel.
    `artifact_kind`, `digest_algorithm`, `system_key`, `media_type`, icon names and `color_hex` do
    not permit NUL.
12. Taxonomy identity remains ID-based. Byte-distinct valid names, including canonically equivalent
    Unicode spellings, never become dictionary keys for destination resolution, export or editing;
    all relationships and updates use UUIDs. The reader preserves those bytes and the UI may display
    visually equivalent names, but no operation may merge, overwrite or drop one because Swift
    `String` equality treats the names as canonically equivalent. This is a required replacement for
    the current name-keyed legacy helpers before v3 production switch. Dimension/value icons and
    value colors are required canonical stored values, not optional presentation hints. A symbol
    that matches `[a-z0-9.]+` but is unknown to the running OS remains wire-valid; UI fallback must
    not mutate its stored bytes or digest.
13. `ease_factor` is finite. Existing finite model values outside normal SM-2 ranges remain valid;
    the wire does not rewrite `-999.9`, `0`, or `100`. `interval_days` is `0...365`, matching the
    effective scheduler contract, and `repetitions` is nonnegative. Before v3 can restore arbitrary
    accepted finite ease/repetition values, `ReviewScheduler` must use checked or saturating
    repetition increment and must clamp/non-finitely guard interval multiplication before
    Double-to-Int conversion; a valid v3 artifact can never be allowed to trigger a numeric trap.
14. Any missing/unreadable image, invalid taxonomy relation, invalid built-in inventory,
    out-of-policy value or writer/reader self-validation failure makes export fail before a user
    artifact is reported. Export never skips, repairs or silently normalizes semantic records.

The JPEG rule closes metadata containers; it does not claim to detect information hidden in visible
pixels or DCT coefficients, which would conflict with preserving the user's visual content.
Before JPEG encoding, the active-image producer applies orientation and performs a color-managed
conversion to 8-bit sRGB for three-component output or DeviceGray for one-component output. It may
strip ICC/APP2 only after that conversion; deleting an embedded Display P3/CMYK profile without
converting pixels is invalid because it changes displayed color. Any alpha is composited onto an
opaque pure-white background before encoding. These producer paths are fixture-tested; the Backup
writer only validates the result and never infers or repairs them.

The redundant `review_state` proposed earlier is removed. `next_review_at_ms IS NULL` is the single
neutral/not-scheduled representation; `last_reviewed_at_ms` is independently nullable. Only the
current `lastReviewedAt` and `nextReviewAt` `.distantPast` sentinels map to NULL; `created_at_ms`
never has sentinel semantics. The reader maps those two nullable columns back to `.distantPast`;
it never maps a NULL review date to the Unix epoch or leaves the model with a different sentinel.

All non-null dates use signed Int64 Unix milliseconds in the closed range
`-1,000,000,000,000,000...1,000,000,000,000,000`. The writer multiplies a finite
`timeIntervalSince1970` by `1,000`, rounds to nearest-even and requires exact Int64 conversion plus
that range. The reader divides by `1,000.0` to construct `Date`, repeats the same encoding, and
requires the same Int64 before mutation. The range is below `2^50` milliseconds, keeping worst-case
binary64 conversion error below half a millisecond; deterministic boundary and seeded-property
fixtures must prove executable closure. Writer quantization vectors construct `Date` from pinned
`Double.bitPattern` values and require:

- `0x3f40624dd2f1a9fc -> 0`, `0x3f589374bc6a7efa -> 2`,
  `0xbf40624dd2f1a9fc -> 0`, and `0xbf589374bc6a7efa -> -2`, proving positive and negative
  nearest-even ties;
- `0x426d1a94a2000004 -> 1000000000000000` and
  `0xc26d1a94a2000004 -> -1000000000000000`, proving accepted boundary ties; and
- adjacent `0x426d1a94a2000005` / `0xc26d1a94a2000005` reject after rounding to one
  millisecond beyond the closed range.

The writer also rejects every non-finite input. Microseconds are deliberately rejected because the
same proof is not total over the useful long-lived `Date` domain. Digests always hash the stored
integer, never `Date` or decimal text.

## 4. Canonical digests

- Hash: SHA-256. It detects corruption and closes inventory; it does not authenticate authorship.
- Domain separator `D` is exact hex
  `536e61704472696c6c204261636b757020763300`
  (`SnapDrill Backup v3` followed by one NUL).
- A field frame is `type:u8 || payloadLength:u64be || payload`. Type bytes are:

| Type byte | Meaning | Payload |
|---:|---|---|
| `00` | NULL | zero bytes |
| `01` | Bool | one byte: `00` false, `01` true |
| `02` | Int64 | eight-byte signed two's-complement big-endian |
| `03` | Double | eight-byte finite IEEE-754 binary64 big-endian |
| `04` | UTF-8 | exact validated bytes, no normalization |
| `05` | UUID | exactly 16 raw UUID bytes |
| `06` | SHA-256 | exactly 32 raw digest bytes |
| `07` | image role | one byte: `00` main, `01` answer |

Every two-digit tag literal in this section is hexadecimal; for example object tag `10` is the
single byte `0x10`, not decimal ten.

All binary64 zero values encode as positive-zero bits; all other finite bit patterns encode
unchanged. Non-finite doubles reject the artifact.

Object tags are `10` backup root, `11` category dimension, `12` category value, `13` library item,
`14` item/category-value join, and `15` item image. The exact canonical field sequences are:

```text
10: singleton, artifact_kind, wire_version, created_at_ms,
    writer_marketing_version, writer_build, digest_algorithm,
    item_count, dimension_count, value_count, item_value_count,
    image_count, image_byte_count
11: id, name, is_multi_value, is_built_in, system_key, sort_order, icon
12: id, dimension_id, name, icon, color_hex, sort_order, created_at_ms
13: id, content, created_at_ms, last_reviewed_at_ms, next_review_at_ms,
    ease_factor, interval_days, repetitions, answer_text
14: item_id, value_id
15: item_id, role, media_type, pixel_width, pixel_height, byte_count,
    content_sha256
```

`record_sha256 = SHA256(D || objectTag || canonical field frames)`. Bool columns use the Bool frame,
not Int64. Nullable fields use the NULL frame. The image digest excludes `blob_id`, `jpeg_bytes`
and `record_sha256`; image bytes are first incrementally counted and hashed, and the recomputed
content digest enters its frame.

`inventory_sha256 = SHA256(D || 10 || root field frames || entries)`. Each entry is
`tableTag || F(06, recomputedRecordDigest)`, where `tableTag` is that row type's object tag, never
the untrusted stored digest. Entries are:

1. dimensions by UUID;
2. values by UUID;
3. items by UUID;
4. joins by `(item UUID, value UUID)`;
5. images by `(item UUID, role byte)`.

Every comparison is unsigned ascending lexicographic byte order. Validation streams one row at a
time and uses checked counters; insertion order, `blob_id`, SQLite rowid and physical order have no
effect. The fixed image index now has the same numeric role order as the digest order.

Minimum known-answer frames:

```text
NULL              000000000000000000
Int64(-1)         020000000000000008ffffffffffffffff
Double(-0 -> +0)  0300000000000000080000000000000000
UTF8("A\0B")      040000000000000003410042
UTF8("")          040000000000000000
role(main)        07000000000000000100
```

Known-answer fixture: four built-in dimensions use UUID bytes ending `01...04` and fields
`(Category,false,true,category,0,folder)`,
`(Source,false,true,source,1,doc)`,
`(Level,false,true,level,2,chart.bar)`, and
`(Tag,true,true,tag,3,tag)`. Their record digests are:

```text
47ffb3869586b5f01d51fa6e294bc72347250454aa5aadea9dfc7878c6156530
584db6973c4a076553d6e4635ec5cb94f7a9eba06dc7aa525f727d67a555bf6b
c5bd86dc31d0cacfe5714bf26588371096ff1a81ecd6840a4ac5fb318ab6d180
3db3d4682a5743131933c13c3354be71636c19fb0fda6f46f9a81654c577b220
```

For root fields `(1, external-complete, 3, 0, fixture, 0, sha256, 0, 4, 0, 0, 0, 0)`
followed by those four entries, the inventory digest is
`9f87daef947811f92c6ffb71d9e84e09da78c3468a32e30ff3b79b0a599af99d`.
Independent implementations must reproduce these values before writer/reader fixtures are accepted.
The tracked Python and Node oracles both assert all six minimum frame bytes and independently
reproduce this minimal inventory digest.

The full semantic known-answer uses UUID bytes that are all zero except the final byte shown below;
`\0` denotes one embedded zero byte. It extends the four built-ins above with dimensions
`05=(Empty,false,false,NULL,4,square)` and
`06=(Context\0上下文,true,false,NULL,5,list.bullet)`. Values are:

```text
11=(dimension 01, Archive, archivebox, #3366FF, 0, 1720000001000)
12=(dimension 04, 重要\0Important, star, #FFCC00, 0, 1720000002000)
13=(dimension 04, Print, printer, #00AA55, 1, 1720000003000)
14=(dimension 06, Home, house, #112233, 0, 1720000004000)
```

Items are:

```text
21=(A\0B,1720000010000,NULL,NULL,-0,0,0,Answer only)
22=(NULL,1720000020000,1720000030000,1720086400000,100,7,3,NULL)
23=(资料 café 👩‍💻,1720000040000,NULL,1720172800000,-999.9,1,1,答案\0Answer)
24=(No answer,1720000050000,1720000060000,NULL,2.5,30,8,NULL)
```

Joins are `(22,11)`, `(22,12)`, `(22,13)`, `(23,14)`. Item 22 uses the 727-byte RGB
fixture as main and the 362-byte grayscale fixture as answer; item 23 reverses those images.
Root metadata is `(1, external-complete, 3, 1720000000000, fixture, 0, sha256,
4, 6, 4, 4, 4, 2178)`.

The primary Python generator and an independent Ruby implementation produce these record digests:

```text
dimension 05 4865c08037f91c486ebd24f470964d609b761a490c249685b579d7485b1b000e
dimension 06 9d6c6859a5b5dde8204433d3041cf90fa9a427bbd796d7c3ad9adf44183e85df
value 11     060278437db774cdf3d560a6e2a8d4c7dda9005344cfe690ed4d91aef5ef576b
value 12     8da487636c598a278ea4d615320a6d2dbd00f995d03afbbca045e6ef5c2ef87e
value 13     c4cefb0605662e16df13db7e6c47c36d885633676cbba38a378c0f8dee42d981
value 14     ef7bb81a78ff2aa153c6ceba8d3dde643f04c09883333bcc32e4451726df3f5c
item 21      947bc0b6fb8ffc4f6e892bc405335a5b08ca87687df0807ee5c13d3ce55e9e6b
item 22      11736c763bfa9aeefb484dca6a26cb3f954d63f9237853ba697011d4d26e236c
item 23      5e8b45d57321290039dd8913d3d58885ba133dfcb9b87e4be0520c2c3a93d48c
item 24      499623d9f742f67ddaff7683a329dbe9458c66d6db861080b454579b26f3188c
join 22:11   74e3c87d0ed7ceaad5de19c9f378863c0a7090b6e6d6b98b00d568db79746b18
join 22:12   359ccc0737f6b18515b0f9843b1f3fd0db661d68bcaf12d25f1f44da5c63e33f
join 22:13   812b30b2f59095d87d0a1518c84763c62a2b2df1611f416769726b3f54cdb71c
join 23:14   343b937f9bffdbde60c4166571d3a9cef7b70a3b1cb87469624807f9867d3439
image 22:0   c11326cb38150214c26b30982347da966b6e7af7c955417251ec3bfec390016d
image 22:1   0117de3483684a01c059ef983e8943adf8b47a8676315e6955b34481c1f6a281
image 23:0   4f8879670d82e25d7a15e40963990a8c5f976c31c7e2fce2b491b4a3a070faf4
image 23:1   2d14b16799a793d4eff6ffe3d1c81feeaa699d5a824662387a5cca3ecf9060c8
```

The full inventory digest is
`1b9a3235235ffa39f71c7bd4d11a592ae7692ef468fecd59333ca3fc62cb872f`.

The permanent empty-string item vector uses UUID bytes ending `25` and fields
`("",1720000070000,NULL,NULL,2.5,0,0,"")`. Its record digest is
`af0acde4b154d286232862c495eaaee7b9413203e91a15a89b36bfa2d2d6ff00`. A valid full-library
generated fixture `V3-P-SEMANTIC-EMPTY-ITEM-WITH-MAIN-IMAGE` attaches a role-`0` main image to this
item and is byte-identity-pinned in `corpus-identities.json`; the row alone is not semantic closure.
Replacing only
`answer_text = ""` with `answer_text = NULL` produces
`d4a37063344973e30def2a3e62f29dbfebee9c750d10e11e8b2fa3660271eaa7`. The tracked Node oracle
`verify-empty-item-vectors.js` and the independent Ruby oracle in `verify-physical-oracle.rb`
reproduce both values, proving that zero-length UTF-8 is preserved and does not collapse into NULL.

No SQLite rowid, page number, physical row order, whitespace, or raw database bytes enter semantic
digests.

## 5. Hostile-file quarantine and open sequence

1. Balance security-scoped access and coordinate the read. Open the coordinated source with
   `O_RDONLY | O_NOFOLLOW | O_CLOEXEC`; require a regular file and record stable descriptor
   identity/size/timestamps.
2. Stream into a fresh app-owned disposable construction directory
   `temporaryDirectory/com.snapdrill.global/<uuid>/restore-validation/` (`0700`) and
   `input.snapdrillbackup` (`O_CREAT | O_EXCL | O_NOFOLLOW`, initially `0600`). This directory is
   outside `AS/LocalLibrary/transactions` and can never contain the only rollback truth or a
   non-terminal journal. Use checked byte accounting, cancellation, capacity checks, file
   synchronization, and parent publication. Recheck source identity/size before closing. Never
   inspect SQLite or ZIP in place at the picked URL.
3. Close the source, make the quarantine file read-only, and prove it is one current-owner,
   link-count-one regular file beneath that exact disposable root, with no journal/WAL/SHM sibling.
   A crash before the atomic `prepared` publication in step 13 can leave only this non-authoritative
   scratch tree; safe startup cleanup may remove it after fixed-root/node validation.
4. Before SQLite, read the 100-byte header with bounded POSIX I/O. ZIP signatures map to
   `developmentBackupUnsupported`. Otherwise require SQLite magic, page size 4096, read/write
   versions 1, reserved bytes 0, payload fractions `64/32/32`, schema format 4, UTF-8 encoding,
   matching application ID and user version, no auto/incremental-vacuum metadata, zero first/total
   freelist pages, equal file-change-counter and version-valid-for fields, a positive header page
   count, and exact `pageCount * 4096 == fileSize` using checked arithmetic. A zero/stale page count
   is not valid v3 writer output. Header expansion bytes `72...91` must all be zero. These are the
   standard big-endian header fields at offsets 16, 18...23, 24, 28, 32, 36, 44, 52, 56, 60, 64,
   68 and 92 plus the reserved expansion range; fields not named here are not compatibility
   identity.
5. Open only the quarantine copy through `sqlite3_open_v2` with a percent-encoded absolute `file:`
   URI derived from the fixed app-owned URL, never a user-controlled URI string. Use
   `mode=ro&immutable=1&cache=private` and flags
   `READONLY | URI | PRIVATECACHE | NOFOLLOW | EXRESCODE`. Before preparing SQL, require
   `sqlite3_db_readonly(db, "main") == 1` and reject any additional attached database.
6. Before the first prepared SQL, a narrow typed C shim applies and reads back
   `SQLITE_DBCONFIG_DEFENSIVE=1`, `TRUSTED_SCHEMA=0`, `WRITABLE_SCHEMA=0`,
   `ENABLE_TRIGGER=0`, `ENABLE_VIEW=0`, `DQS_DDL=0`, `DQS_DML=0`, and foreign keys on. For
   extension loading, `sqlite3_compileoption_used("OMIT_LOAD_EXTENSION") == 1` is the preferred
   compiled-out proof; otherwise the shim must set and read back
   `SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION=0`. The iOS SDK does not expose
   `sqlite3_enable_load_extension`, so the contract does not require a private declaration. The
   shim applies every `sqlite3_limit` below and sets mmap to zero with
   `SQLITE_FCNTL_MMAP_SIZE`. It also requires
   `sqlite3_compileoption_used("ENABLE_DBSTAT_VTAB") == 1`; the exact bounded physical-closure
   algorithm below has no fallback to an in-memory whole-database checker. Except for the explicit
   compiled-out extension-loading branch, any unsupported, failed or mismatched hardening
   operation rejects the file; there is no permissive fallback.
7. Install a deny-by-default authorizer and cancellation/progress handler before preparing even a
   PRAGMA. The authorizer permits only the fixed reader statements, exact read columns and required
   PRAGMAs; it denies attach/detach, writes, transactions, schema mutation, virtual-table creation,
   arbitrary functions and temp-schema access. The fixed setup sets and reads back
   `query_only=ON`, `cell_size_check=ON`, `cache_size=-4096`, `temp_store=FILE`,
   `automatic_index=OFF`, and `threads=0`. Negative cache size requests 4096 KiB from SQLite; it is
   a cache target, not a claim that process RSS is exactly 4 MiB.
8. As the first schema-dependent statement after hardening, compare the exact ten-row
   `sqlite_schema` manifest (`type`, `name`, `tbl_name`, byte-exact stored `sql`) against the
   canonical DDL, ignoring only `rootpage` and row order. Require exact TEXT storage classes and
   expected byte lengths before copying each value, reject an eleventh row immediately, and require
   DONE after the ten expected rows. Until this succeeds no attacker-supplied object or index name
   may be used by DBSTAT, `INDEXED BY`, foreign-key or semantic traversal.
9. Prove bounded physical closure before semantic traversal:
   - Preallocate a zeroed app-owned disk bitset of `ceil(pageCount / 8)` bytes and access it through
     one fixed-size memory window. Stream normal, non-aggregate
     `dbstat('main')` rows for `name`, `pageno`, `pagetype`, `pgoffset`, and `pgsize`. Require an
     allowed schema-object name (or `sqlite_schema`), page number in range, page size 4096,
     `pagetype` exactly `internal`, `leaf`, or `overflow`, and a previously clear bit. For
     `internal` and `leaf` rows also require checked offset `(pageno - 1) * 4096`; do not use
     `pgoffset` as an overflow-page oracle because SQLite 3.51 reports the owning b-tree page
     offset for those rows;
     then set it. After DONE, a sequential bitset pass requires every database page exactly once
     except SQLite's single lock-byte page 262145 when `fileSize > 1,073,741,824`; DBSTAT and SQLite
     both intentionally omit that page. Freelist and pointer-map pages are already forbidden.
   - For each of the four explicit indexes, step an `INDEXED BY` key/primary-key stream beside a
     fixed owning-b-tree stream and require typed row-for-row equality through DONE:
     `(name,id)`, non-null `(system_key,id)`, `(dimension_id,name,id)`, and
     `(item_id,role,blob_id)` respectively. `NOT INDEXED` is insufficient for a `WITHOUT ROWID`
     table because SQLite may still select a covering secondary index; the owning streams therefore
     force `sqlite_autoindex_category_dimension_1` or
     `sqlite_autoindex_category_value_1`, while rowid `item_image` uses `NOT INDEXED`.
     Temp sorting is file-backed. Source semantic queries likewise force the owning table or
     primary-key b-tree rather than trusting a secondary index.
   - A full `PRAGMA integrity_check(1)` may run only as additional defense when checked page-bitmap
     and measured process headroom fit a dedicated memory budget. Its absence can never reject an
     otherwise valid large v3 file: the error-count argument does not bound SQLite's page bitmap.
10. Stream every selected cell's exact storage class and bounded byte/domain constraints first,
    before any coercive accessor, UTF-8 decoding, row hashing or allocation from an untrusted value.
    This first pass includes UUID/digest lengths, strict UTF-8, CHECK-equivalent constants/ranges
    and bounded JPEG byte framing, so a malformed child ID or wrong-class foreign-key cell has one
    observable rejection stage rather than being masked by relationship closure. Then require
    `foreign_key_check` to return DONE before its first row and stream the remaining cross-row
    semantic constraints, digests and normalized JPEG grammar. No user-provided SQL is ever
    prepared. The authorizer permits the fixed `sqlite_schema`, eponymous DBSTAT, index-parity,
    foreign-key and semantic statements, not arbitrary virtual tables or SQL.
11. Only a completely validated neutral stream can enter candidate-generation construction.
   Quarantine validation never mutates the active library. “Neutral stream” is an interface and
   not an all-library DTO graph: pass one validates the entire immutable quarantine file; pass two
   replays the same file into a fresh candidate generation in bounded rows/chunks. Destination
   relationships are resolved through indexed IDs in bounded batches, not an unbounded UUID/object
   dictionary. Images are incrementally re-read and revalidated while copied into the candidate;
   no first-pass image or decoded raster is retained in memory for the second pass.
12. Before that candidate can be called complete, close and reopen it through a dedicated
    no-repair/no-rebuild/no-in-memory-fallback verifier. Re-encode its local semantics through the
    same canonical v3 digest stream and require exact equality with the source item, dimension,
    value, join and image counts, every stable ID and field, every `(itemID,valueID)` tuple, every
    `(itemID,role,byteCount,contentSHA256)` tuple, and the source `inventory_sha256`. Optional
    resolution, `compactMap`, synthesized built-ins, dropped images and name-keyed joins are fatal.
13. Restore consumes the effective operation admission, closed-generation prestate, transaction
    publication, selector commit, reconciliation, rollback and incident grammar from the Local
    Library Data Contract. This wire candidate does not redefine journal fields, phases, filesystem
    roots or mutation-barrier lifetime. Its responsibility ends at producing a completely validated
    neutral stream and replaying it into the unpublished candidate generation in bounded passes.
    Quarantine work may occur before protected mutation only in the disposable root; active-library
    publication begins only through the owning data contract and remains all-or-nothing.

`immutable=1` is valid only because the app owns the copied file and enclosing directory, has
closed every writer, proved link count one, and exposes no mutable path. `NOFOLLOW` protects path
opening but does not replace the copy-and-identity proof.

## 6. Connection limits and bounded work

The reader applies these exact connection limits:

| Limit | Value |
|---|---:|
| `SQLITE_LIMIT_LENGTH` | 67,108,864 |
| `SQLITE_LIMIT_SQL_LENGTH` | 4,096 |
| `SQLITE_LIMIT_COLUMN` | 32 |
| `SQLITE_LIMIT_EXPR_DEPTH` | 20 |
| `SQLITE_LIMIT_COMPOUND_SELECT` | 4 |
| `SQLITE_LIMIT_VDBE_OP` | 50,000 |
| `SQLITE_LIMIT_FUNCTION_ARG` | 8 |
| `SQLITE_LIMIT_ATTACHED` | 0 |
| `SQLITE_LIMIT_LIKE_PATTERN_LENGTH` | 256 |
| `SQLITE_LIMIT_VARIABLE_NUMBER` | 32 |
| `SQLITE_LIMIT_TRIGGER_DEPTH` | 0 |
| `SQLITE_LIMIT_WORKER_THREADS` | 0 |

The connection uses `cache_size=-4096`, mmap zero, private cache, file-backed temp, no automatic
index, and no worker thread. Image BLOB I/O uses bounded chunks (256 KiB is an implementation
default, not a wire-compatibility value). Text materialization is bounded by the effective S1-A
per-value ceiling. A compressed image is never materialized as one `Data`: validation
streams it to an untrusted disposable spool, hashes and marker-checks it incrementally, then uses a
file-backed full decode one image at a time. Neither validation nor construction materializes the
whole row inventory, all IDs, all relationships or all images; source and destination indexes
provide bounded replay.

Work is cancellable and has a deterministic no-forward-progress deadline. For file size `S`, each
fixed statement or non-SQL bounded loop receives
`30 seconds + ceil(S / 16,777,216) seconds`, calculated with checked monotonic-duration arithmetic.
The deadline is reset only after externally observable bounded progress: one schema/DBSTAT/index/
semantic row has been fully type-checked and consumed, one 256 KiB file/BLOB/JPEG chunk has been
read or written and checked, or a fixed zero-row check reaches DONE. A
`sqlite3_progress_handler` installed before the first statement runs every 1,000 virtual-machine
instructions and aborts when cancellation is requested or the current deadline has expired; its
own callbacks never reset the deadline. Before the selector commit barrier, each check evaluates
cancellation before deadline so simultaneous observation has one deterministic result. POSIX copy,
hash, marker, decode and destination-validation loops apply the same deadline between bounded
progress events.

Before selector replacement, deadline expiry returns a stable retryable
`backupValidationTimedOut` operation result, deletes only proved disposable scratch, and leaves the
selector and active generation byte-identical. It does not permanently classify the source bytes
as corrupt. After selector replacement begins, the owning Local Library Data Contract routes every
deadline/cancellation result through reconciliation rather than returning timeout or cancelled. The
exact formula and callback cadence are qualified on the minimum supported runtime
and device with valid generated files across the size matrix before production conformance, not as
a circular prerequisite for contract ratification. SQLite VM-step totals are not wire identity
because they vary by build and optimizer; only the progress callback cadence and the monotonic
no-progress deadline are fixed. Every prepared statement and query plan remains fixed by this
contract, every semantic loop advances one validated row or bounded byte chunk, and every counter
is checked against the header size, root inventory or conditional per-value ceiling before
allocation or mutation.

No total file, item, or image-set cap is allowed. Capacity preflight may reject only proven
insufficient storage using checked lower bounds and the platform available-capacity API; otherwise
the operation attempts its write and maps `SQLITE_FULL`/`ENOSPC` to `insufficientStorage`.

Stable result mapping is closed rather than left to each implementation: hostile
structure/schema/digest/JPEG failures are `backupIntegrityFailed`; duplicate/dangling/nil taxonomy
or image relationships are `backupReferenceMismatch`; capacity failure is `insufficientStorage`;
D4S settlement or D3-B prestate freeze failure is `prestateSnapshotFailed`; generation publication
failure is `publicationFailed`; inability to restore old is `rollbackFailed`; and a blocking
incident is `recoveryDecisionRequired`. User cancellation observed before the selector barrier is
terminal outcome `cancelled`, never an error category; after that barrier it cannot override the
reconciled publication result. Because pre-barrier timeout is explicitly retryable and does not
classify source bytes as corrupt, ratified P2-F-A uses `backupValidationTimedOut` and the Backup
feature lifecycle `idle/running` plus terminal `completed/cancelled/failed`. An implementation may
not map timeout to `backupIntegrityFailed` or describe cancellation as failure.

## 7. Writer finalization

- The writer obtains the closed immutable source snapshot through the Local Library Data Contract
  §§4.2–4.3. It closes admission, drains registered mutations and settles pending delete/undo under
  effective D4S-A. Once that source snapshot is durable, detached and independent of the active
  runtime, the owning contract releases the mutation barrier; v3 encoding continues from the
  immutable snapshot and does not block later active-library mutation. No pending marker, deadline
  or internal operation phase enters the external wire.
- Before enabling the writer, production bootstrap must seed exactly the four built-ins by stable
  `system_key`, and every production mutation API must emit required `[a-z0-9.]+` symbols and
  normalized uppercase `#RRGGBB`, enforce the P2-C-A content-or-main-image invariant, distinct
  answer NULL/empty semantics, image-role uniqueness, nonempty taxonomy names, effective M1-A,
  hardened Review numeric transitions, and effective S1-A plus P2-D-A. There is no user-data
  migration or export-time repair path for the zero-user pre-production epoch. A stored
  `interval_days` outside
  `0...365` is an internal-consistency failure: export produces no artifact and gives repair
  guidance; it is never silently clamped in Backup. A capability that remains `hidden` is not a
  Release 1 producer; before any retained CSV/v2/test-only path becomes reachable again, it must
  satisfy these same invariants.
- Build a fresh app-owned database; never copy or mutate the live SwiftData store.
- Before the first database write, set `SQLITE_FCNTL_RESERVE_BYTES = 0` and require `SQLITE_OK`;
  Apple-host SQLite defaults are not wire policy. Then set page size, UTF-8 encoding, application
  ID, version, no-auto-vacuum and DELETE journal mode before creating the byte-exact canonical
  schema. After close, the raw-header verifier is the authoritative readback and requires byte 20
  to be zero. Never reuse a failed candidate.
- Enable foreign keys, set and read back `PRAGMA synchronous = EXTRA` and
  `PRAGMA fullfsync = ON`, insert in bounded transactions, and use incremental BLOB writes. EXTRA
  adds the DELETE-journal directory sync after unlink; fullfsync requests Darwin `F_FULLFSYNC`
  where the VFS supports it. The final wire image is byte-identical to the active canonical
  metadata-free JFIF from section 3. Capture/`ImageStorage` must be upgraded and fixture-proved to
  apply orientation, color-manage wide-gamut/CMYK input, composite alpha onto opaque white and
  canonicalize before active storage; Backup does not silently rewrite a noncanonical active image
  and instead fails the export.
- Write and verify all per-record digests. Write `backup_root` last.
- Commit, finalize to DELETE journal mode, close all handles, synchronize the database and enclosing
  directory, and make absence of journal/WAL/SHM and unknown siblings an explicit assertion.
- Require zero freelist pages and the exact raw-header invariants from section 5. Fresh construction
  performs no delete and needs no final `VACUUM`.
- Run the same hardened v3 reader against the closed candidate and compute its checked byte count
  plus whole-file SHA-256 before publication.
- The writer publishes only an App-owned share source at
  `temporaryDirectory/com.snapdrill.global/<uuid>/Backup.snapdrillbackup`. It first creates a
  destination-local `O_EXCL | O_NOFOLLOW` staging regular file in that same directory, streams the
  closed candidate into it with checked length/hash, synchronizes the file, atomically renames it to
  the final basename, and synchronizes the parent. It then reopens the final visible path, requires
  the same byte count and whole-file SHA-256, and runs the hardened reader once more. Collision,
  node substitution, short copy or cross-device replacement fails before rename and removes only
  proved staging. A parent-sync or final postcondition failure after rename returns no URL and
  retains the exact App-owned final node under the operation cleanup/retry record; it is never
  mislabeled as an external user-owned success or blindly deleted through a changed identity.
- Only that revalidated final URL may be handed to `UIActivityViewController`. The system share
  destination owns its copy result; SnapDrill does not claim that an external provider committed a
  durable copy. The App-owned source remains available until the share sheet dismisses, then follows
  the effective explicit cleanup/retry rule. A future direct file-exporter path requires its own
  coordinated destination-publication contract and cannot reuse this success claim implicitly.
- Failure, source invalidity or cancellation leaves no artifact reported as successful and does not
  mutate the active library.

Fresh construction and closure yield a page-aligned schema-format-4 database with no freelist or
sidecar. Physical SQLite bytes are not a deterministic oracle.

## 8. Standard SQLite extraction recipe

This is diagnostic interoperability for a trusted fixture or a byte-identical copy already accepted
by the hardened v3 reader. The SQLite shell is not the hostile-file validator and this recipe does
not prove schema, digest, JPEG, sidecar or semantic integrity. Use the official `sqlite3` shell with
`writefile()` and a fresh output directory:

```bash
set -eu
umask 077
output=extracted
staging=.extracted.tmp.$$
test ! -e "$output"
test ! -e "$staging"
mkdir "$staging"
mkdir "$staging/images"
cd "$staging"
sqlite3 -readonly ../Backup.snapdrillbackup <<'SQL'
.bail on
.headers on
.mode tabs
.nullvalue NULL

.once header.tsv
SELECT application_id, user_version FROM pragma_application_id, pragma_user_version;
.once backup_root.tsv
SELECT singleton, hex(CAST(artifact_kind AS BLOB)), wire_version, created_at_ms,
       hex(CAST(writer_marketing_version AS BLOB)), hex(CAST(writer_build AS BLOB)),
       hex(CAST(digest_algorithm AS BLOB)), item_count, dimension_count, value_count,
       item_value_count, image_count, image_byte_count, hex(inventory_sha256)
FROM backup_root WHERE singleton = 1;
.once category_dimension.tsv
SELECT hex(id), hex(CAST(name AS BLOB)), is_multi_value, is_built_in,
       CASE WHEN system_key IS NULL THEN NULL ELSE hex(CAST(system_key AS BLOB)) END,
       sort_order, hex(CAST(icon AS BLOB)), hex(record_sha256)
FROM category_dimension ORDER BY id;
.once category_value.tsv
SELECT hex(id), hex(dimension_id), hex(CAST(name AS BLOB)), hex(CAST(icon AS BLOB)),
       hex(CAST(color_hex AS BLOB)), sort_order, created_at_ms, hex(record_sha256)
FROM category_value ORDER BY id;
.once library_item.tsv
SELECT hex(id),
       CASE WHEN content IS NULL THEN NULL ELSE hex(CAST(content AS BLOB)) END,
       created_at_ms, last_reviewed_at_ms, next_review_at_ms,
       printf('%!.17g', ease_factor), interval_days, repetitions,
       CASE WHEN answer_text IS NULL THEN NULL ELSE hex(CAST(answer_text AS BLOB)) END,
       hex(record_sha256)
FROM library_item ORDER BY id;
.once item_category_value.tsv
SELECT hex(item_id), hex(value_id), hex(record_sha256)
FROM item_category_value ORDER BY item_id, value_id;
.once item_image.tsv
SELECT blob_id, hex(item_id), role, hex(CAST(media_type AS BLOB)),
       pixel_width, pixel_height, byte_count, hex(content_sha256), hex(record_sha256),
       lower(hex(item_id)) || CASE role WHEN 0 THEN '-main.jpg' ELSE '-answer.jpg' END
FROM item_image ORDER BY item_id, role;

CREATE TEMP TABLE image_write_result (
    path TEXT PRIMARY KEY,
    expected INTEGER NOT NULL CHECK(expected > 0),
    written INTEGER NOT NULL,
    CHECK(written = expected)
) STRICT, WITHOUT ROWID;
INSERT INTO temp.image_write_result(path, expected, written)
SELECT 'images/' || lower(hex(item_id)) ||
           CASE role WHEN 0 THEN '-main.jpg' ELSE '-answer.jpg' END,
       byte_count,
       writefile(
           'images/' || lower(hex(item_id)) ||
               CASE role WHEN 0 THEN '-main.jpg' ELSE '-answer.jpg' END,
           jpeg_bytes
       )
FROM item_image ORDER BY item_id, role;
.once image_files.tsv
SELECT path, written FROM temp.image_write_result ORDER BY path;
SQL
cd ..
test ! -e "$output"
mv "$staging" "$output"
```

Text is emitted as hex so embedded NUL is not truncated; CASE distinguishes NULL from an empty byte
sequence. The temporary STRICT table converts `writefile()` NULL/short-write results into a SQL
constraint error, so `.bail on` and `set -e` prevent publication; the fresh staging directory is
renamed only after every SQL and shell step succeeds. `writefile()` may materialize one BLOB in the
shell and is not the production incremental I/O path.

## 9. Version compatibility

- Profile ZIP v1/v2: explicit `developmentBackupUnsupported` before ZIP extraction or mutation.
- Correct SQLite magic but wrong application ID: `backupFormatUnsupported`.
- SnapDrill family version 0...2: `backupFormatUnsupported`; no accepted SQLite predecessor exists.
- Version 3: this exact object/schema/semantic reader only.
- Version greater than 3: `backupFormatUnsupported` with stable internal presentation reason
  `requiresNewerApp`. User-visible wording and action belong to the Backup feature contract, not
  this wire grammar.
- Every app after the first non-PO distribution retains an immutable v3 reader.
- A future app converts a valid old artifact into a version-neutral semantic stream and writes a
  fresh current-version candidate. It never `ALTER`s, attaches, or writes the source in place.
- No partial restore, salvage, merge, encryption, or automatic retention is implied by v3.

## 10. Fixtures and adversarial corpus

Permanent fixtures:

1. fixed English and Simplified-Chinese seeded empty libraries, each with four built-in dimensions,
   its exact default values, no items/images and pinned IDs/times rather than runtime randomness.
   `generate-empty-fixtures.py` recreates both twice, validates them through the independent
   reference oracle, and pins semantic-manifest SHA-256
   `06e8291bd91f55f55b597f1b05aacbff66c55555ff09145bb9b1dc6a3b8dc7ee`;
   the English and Simplified-Chinese root inventories are respectively
   `6703a7d6927174a7edd6ecb2bb30dba4f281725d366cb06178866790b3013cdd` and
   `15326e585fa2c3de3e03d8ae63309202d55d943a65cb33c5086b4bda971cc00c`;
2. one fixed full library with neutral/scheduled review state, text-only, image-only and text+image
   items, independent answer text/image combinations, zero-link items, all built-ins, empty and
   populated custom dimensions, Unicode including embedded NUL, finite ease factors
   `-999.9/0/100`, and fixed IDs/times/digests; the semantic positive corpus adds the pinned
   empty-content/main-image item, while tracked Node and Ruby known-answer oracles reproduce the
   NULL-versus-empty answer digest pair from section 4;
3. exact-ceiling positives: 1 MiB text, 1024-byte names and 256-byte icons, plus a fully valid
   2000x2000 canonical JPEG whose pinned byte count is no greater than 50 MiB. Separate
   deterministic 256 KiB-chunk stream probes at exactly 52,428,800 and 52,428,801 bytes prove the
   inclusive image-byte gate; the exact-size stream is not claimed to be a semantically valid JPEG.
   The 50 MiB value is a defensive maximum, not a claim that the canonical JPEG language or a
   production encoder contains an output of exactly that size;
4. digest byte vectors and independently generated full row/root known answers, including
   `+0/-0`, NULL/NUL, role order and every BLOB chunk boundary. The accepted case
   `V3-P-SEMANTIC-IMAGE-BLOB-ID-REVERSED` assigns blob IDs `4,3,2,1` in semantic image order and
   proves the inventory remains the canonical value, so insertion/rowid order cannot become digest
   order;
5. canonical JPEG positives for grayscale/RGB SOF0, and writer outputs for
   all supported orientations/color spaces on retained simulator/device OS versions. The minimum
   SOF0 pair is fixed now: `canonical-rgb-sof0-2x2.jpg` is 727 bytes with SHA-256
   `3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d`; and
   `canonical-gray-sof0-2x2.jpg` is 362 bytes with SHA-256
   `cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414`. Both begin with the fixed
   JFIF 1.02 header, decode as 2x2, and contain three and one components respectively.
   Both retained files pass the raw grammar regression. The regression also mutates SOF0 to SOF1
   and SOF2 and requires fail-closed rejection, inserts every APP
   marker and COM into the RGB SOF0 fixture and proves normalization returns its canonical bytes;
   it does not claim retained independent pre/post-normalization pixel evidence for both.
   `canonical-rgb-sof0-2000x2000.jpg` is a 422,558-byte dimension-ceiling fixture generated on the
   iOS 26.5 Simulator from fixed sRGB pixels, with SHA-256
   `5307c20da2979646f422606035d5c8d22fba30f79c083a61fb945ee58487fdef`.
   The 2000x2000 fixture's pre-normalization and normalized `djpeg -strict` PPM outputs are both
   12,000,017 bytes with
   SHA-256 `73ee6cb684de262b2e19b4493b56c9e376ffd0b24acd227c9222cde41d0c8247`;
6. one permanently retained physical v3 file, its ten-row byte-exact schema manifest and an
   independent semantic extractor. The corrected `iOS-26.5-full-v3.sqlite` oracle was initialized
   by an iOS 26.5 Simulator / SQLite 3.51.0 C probe that set and read back
   `SQLITE_FCNTL_RESERVE_BYTES = 0` before the first write. The host `/usr/bin/sqlite3` 3.51.0 CLI
   then populated that same host-visible file from the exact DDL and full-row loader above. The
   retained `reproduce-physical-oracle.sh` compiles and runs that initializer, applies both SQL
   inputs and requires byte identity with the retained oracle: 53,248 bytes / 13 pages, reserve byte
   and header expansion all zero, no freelist or sidecar, root inventory
   `1b9a3235235ffa39f71c7bd4d11a592ae7692ef468fecd59333ca3fc62cb872f`, and SHA-256
   `f5568d8621c9e1c577c4972153dae75056abb4cc7e2ada996c141ae47b6b07fc`.
   The provenance record pins the simulator, SDK, compiler, initializer binary, both SQL inputs,
   reproduced output and exact-match result. This physical-oracle hash is not contract evidence
   until the fixture, build recipe and independent extractor are tracked in the same effective
   slice;
7. deterministic timestamp vectors for both closed-range boundaries, neighboring out-of-range
   rejections and a fixed-seed property corpus proving Int64 milliseconds survive
   `Double / 1,000` then nearest-even `* 1,000` exactly;
8. a compiled C capability probe on the minimum supported iOS runtime and every retained release
   qualification runtime, covering the open flags, every required db-config/limit/file-control,
   compile-time extension-loading branch and `sqlite3_db_readonly`. A local iOS 26.5 /
   SQLite 3.51.0 probe has passed; this draft package owns the source, exact 33-line output and
   runner identity, but they do not become contract evidence until the package is tracked in the
   effective authority slice. The current machine has no iOS 26.0 runtime, so minimum-OS
   evidence remains a release prerequisite rather than being inferred from 26.5;
9. bounded deterministic hostile generators that retain source but create mutated databases only
   in temporary roots. The logical-type matrix has 207 cases (196 generated and 11 SQLite storage
   invariants documented as unobservable) with semantic-manifest SHA-256
   `1f02b9c5db77484e1d8b790040902323f16f214ac4b6e2370ac2ddd4b3d7c1fb`; the CHECK matrix has
   67 cases and `9f1a7c9a7b435c9a6f4a24722801a9917acd69490f9d954e3b49d4139dac8353`; the cross-row,
   digest, every-TEXT-column UTF-8 and JPEG semantic matrix has 59 cases and
   `6991df1ead81c50ba0cdbf214cc8b3afbe73cae58613fc4bf99c7f1eca8deb22`; the raw JPEG grammar
   negative matrix has 59 byte-identity-pinned cases and
   `00ab96ea1e255c93ca09d28fc3aa34d4c1920c3de0bd2b5ea76d49d8a64d9ad0`; the header,
   exact-schema, reference-resource, physical-closure and sidecar matrix has 36 cases and
   `95b9c2a599be186b978281667f22917bd30763345832c0eae2b4c53441508ec5`; and the real POSIX
   regular-file, exclusive-create, symlink, hard-link, descriptor-pin and source-mutation matrix has
   11 cases and `d12b65fc12946b3f73620bc57b1b8d2bdc7a75b491a9fcfe07c1693766bd9f10`.
   Every matrix runs twice and fails if its pinned case manifest changes; every SQLite matrix also
   compares generated physical bytes. A separate retained identity manifest pins each generated
   hostile database's case ID, byte count and SHA-256 rather than retaining the hostile binaries.
   The structure matrix includes a real non-UTF-8 `sqlite_schema.name` file that must return a
   staged `schema:unreadable` rejection, plus an in-process raw-cursor case proving invalid name
   bytes compare as `schema:manifest` instead of escaping as a Unicode exception.
   Eight duplicate-identity databases are physically built under relaxed key definitions, vacuumed,
   and then restored to the byte-exact canonical schema manifest, proving that the reader rejects
   duplicate primary/unique identities independently of declared DDL. `item_image.blob_id` is an
   `INTEGER PRIMARY KEY` rowid alias, so a ninth engine-invariant case proves duplicate physical
   identity is unconstructible through SQLite; the reader still re-proves it in depth.
   The earlier independent review is stale because later generator and candidate bytes changed; it
   is deliberately excluded from this package. The final read-only review must bind the manifest v2
   aggregate review-input SHA-256 covering every package artifact except the two review-output files
   themselves. This includes the candidate, validators, digest/JPEG oracles, all generators, exact
   schema, fixtures, evidence and corpus identity lock. There is no free-text post-review delta
   exemption: any covered byte change invalidates the review.

Pin each retained fixture file hash for identity. Compare new writer output through canonical rows,
record digests, root and normalized JPEG hashes, not raw SQLite bytes. The physical fixture hash
protects fixture identity but is not a cross-writer determinism oracle.

Evidence is split to avoid making the contract depend circularly on its future production reader:

- **Contract-ratification evidence** lands with the authority doc: exact DDL/schema manifest, one
  corrected physical oracle, two tiny canonical SOF0 JPEGs plus one 2000x2000 dimension-ceiling
  JPEG, canonical digest/timestamp vectors, deterministic
  limit/hostile generators, an independent reference validator with exact staged outcomes, an
  independent trusted-fixture extractor, raw JPEG marker grammar and the typed C SQLite
  capability-probe source plus retained iOS 26.5 result. Generated 50 MiB and 50 MiB-plus-one
  byte-gate probes live only in bounded temporary test roots and are not committed.
- **Implementation conformance evidence** lands before production switch: hardened-reader outcomes,
  replay/cardinality/edit preservation, operation/deadline/fault behavior, generation/selector
  publication, minimum-supported-runtime capability/deadline qualification, built-app UTType
  declaration, full above-200-MiB and above-1-GiB valid-library round trips, share-source failure
  handling and D4S settlement.

The bundled Python reference validator is a bounded contract-corpus oracle, not a production v3
reader: it deliberately refuses files above 64 MiB and tables above 10,000 rows so adversarial
qualification itself cannot become an unbounded allocation surface. Those private harness limits
do not narrow the wire contract or justify rejecting a larger valid user library. The production
reader must separately prove streaming resource bounds and the large-library round trips above.
After exact schema validation, the reference oracle scans at most 10,001 literal `1` values from
each owning table and applies this private row cap before DBSTAT/index-parity work or materializing
any user value.

Every row below has a runnable owner at its named gate. A prose name or a production test claimed as
already passing in the contract-only package does not satisfy either gate:

| Case ID | Gate | Required oracle |
|---|---|---|
| `V3-P-TYPEDECL` | production | Built app declaration resolves exactly `com.snapdrill.global.backup`, preferred extension `snapdrillbackup`, non-dynamic exported ownership, and conformance to `public.data`, `public.content`, and `public.database`; removing any declaration field fails. |
| `V3-P-EMPTY-EN`, `V3-P-EMPTY-ZH`, `V3-P-FULL` | both | Contract extractor equals pinned answers; production hardened reader accepts and destination semantic digest matches. |
| `V3-P-TIMESTAMP-MS` | both | Contract vectors prove stored-millisecond round trip plus the pinned writer `Double.bitPattern` ties/boundaries; production writer and reader reproduce them and reject non-finite or neighboring out-of-range values. |
| `V3-P-TAXONOMY-CANONICAL-NAMES-WIRE` | contract | Two distinct UUID rows with byte-distinct canonically equivalent valid names survive SQLite storage and canonical digest extraction without normalization or merge. |
| `V3-P-TAXONOMY-CANONICAL-NAMES` | production | Distinct UUIDs plus byte-distinct canonically equivalent names survive export, validation, replay, publication, ID-based edit and re-export without merge/overwrite/loss. |
| `V3-P-LIMIT-TEXT`, `V3-P-LIMIT-NAME`, `V3-P-LIMIT-ICON` | both | Contract generators prove exact-byte and plus-one structures; production producers and reader accept exact limits and reject plus-one before active mutation. |
| `V3-P-LIMIT-JPEG-DIMENSIONS` | both | Contract evidence includes one fully valid 2000x2000 canonical JPEG and dimension-over mutations; production accepts a valid 2000x2000 producer output and rejects 2001xN or Nx2001 before active mutation. |
| `V3-P-LIMIT-JPEG-BYTES` | both | A deterministic chunk stream proves that byte 52,428,800 is inside and byte 52,428,801 is outside the size stage; the exact-size stream need not satisfy JPEG grammar. Production enforces the same inclusive hard stop before full decode or active mutation. |
| `V3-P-JPEG-LARGE-VALID` | both | One pinned 2000x2000 JPEG below 50 MiB passes raw grammar and independent full decode; it is not claimed to be the largest encodable member. |
| `V3-P-LOCKBYTE-1G` | production | Deterministic qualification generator produces a valid file above 1 GiB; the omitted lock-byte page rule accepts and full restore round-trips. The binary is not committed. |
| `V3-N-CHECK-<table>-<column>` | both | Direct-cell construction violates every CHECK-only constant/domain/grammar while preserving schema. `check-targets.json` binds every case ID to one exact staged rejection; a same-table prefix is insufficient. It recomputes every dependent digest when the hostile value still has a canonical frame; a value that makes canonical framing undefined is rejected before digest comparison and its stored digest is not used as an oracle. The independent extractor and production reader reject before mutation. |
| `V3-N-TYPE-<table>-<column>-<class>` | both | Parameterized direct-cell mutation covers every non-allowed logical class observable through `sqlite3_column_type` and rejects before coercion; valid REAL-affinity integer serial encoding remains `SQLITE_FLOAT` and is not a negative case. |
| `V3-N-UTF8-TRUNC`, `V3-N-UTF8-OVERLONG`, `V3-N-UTF8-SURROGATE`, `V3-N-UTF8-REPLACEMENT-FALLBACK` | both | Malformed TEXT bytes reject; no replacement decoding or C-string truncation occurs. |
| `V3-P-UTF8-UFFFD` | both | Deliberately stored valid UTF-8 bytes `EF BF BD` decode and re-encode byte-exactly; the scalar U+FFFD is valid user text and is not confused with decoder fallback. |
| `V3-N-HEADER-*` | contract | Each named 100-byte header invariant and exact page-count/file-size closure rejects at its first staged reference-validator rule. |
| `V3-N-SCHEMA-*` | both | Extra/missing/wrong-type/wrong-name/wrong-table/wrong-SQL objects and non-UTF-8 object names reject with a staged schema result before DBSTAT or `INDEXED BY` uses an attacker-controlled name. |
| `V3-N-PHYSICAL-*` | contract | A header-consistent appended unowned page rejects on exact page closure, and a byte-only secondary-index drift rejects on indexed-versus-owning-b-tree parity before semantic traversal. |
| `V3-N-REFERENCE-ROW-LIMIT` | contract | A schema-valid file with 10,001-plus rows in one table rejects at the private reference row cap before physical parity or value materialization; this is a harness-resource test, not a wire limit. |
| `V3-N-REFERENCE-FILE-LIMIT` | contract | A sparse 64 MiB-plus-one file rejects at the private reference file cap before header read or SQLite open; this is a harness-resource test, not a wire limit. |
| `V3-N-SIDECAR-*`, `V3-P/N-FS-*` | contract | Real POSIX nodes prove no-follow/exclusive create, regular/current-owner/link-count-one/read-only quarantine, lexical sidecar rejection including a dangling symlink, fixed-root type/mode validation, source-size recheck and descriptor-pinned reads across path substitution. |
| `V3-P-REVIEW-EXTREME` | production | Restore wire-extreme finite ease/repetition values, then run `scheduleNextReview` and `intervalDescription` without numeric trap. |
| `V3-P-M1A-EDITOR-BLOCK` | production | Under effective M1-A, violating multi-to-single transition reports affected count and leaves dimension/links unchanged. |
| `V3-P-ALPHA-*` | production | Every supported alpha/orientation/color-space producer path yields the pinned canonical visual result and wire JPEG grammar. |
| `V3-N-PRODUCER-INTERVAL` | production | A stored interval above 365 returns the explicit internal-consistency/repair result before artifact publication; no silent clamp occurs. |
| `V3-N-DEADLINE-STALL` | production | A fixed hostile statement with no semantic progress deterministically returns `backupValidationTimedOut`; cancellation is distinct. |
| `V3-F-SELECTOR-BARRIER` | production | Cancellation-first and deadline-second sampling immediately before selector replacement returns `cancelled`/timeout with old proved unchanged; the same signals after rename cannot escape reconciliation or report those terminal outcomes. |
| `V3-F-PRE-*` | production | Fault at every scratch copy, sync, prestate, generation move, selector replacement and journal update proves old/new behavior from the effective grammar. |
| `V3-N-DEST-COUNT`, `V3-N-DEST-ID`, `V3-N-DEST-JOIN`, `V3-N-DEST-IMAGE`, `V3-N-DEST-VALUE` | production | Fault-injected destination loss/coercion fails post-replay semantic/cardinality validation and never commits the selector. |
| `V3-F-EXPORT-*` | production | Fault at each final share-source write/sync/rename/reopen/hash/reader boundary returns no URL and never exposes a partial final basename. |
| `V3-R-D4S-UNDO`, `V3-R-D4S-EXPIRE`, `V3-R-D4S-FAIL`, `V3-R-D4S-RESTORE` | production | Under D4S-A, undo settles then includes the item; expiry settles then excludes it; failure emits no artifact/mutation; restore cannot race a later delete executor. No pending marker reaches wire. |

The adversarial corpus independently mutates header/version/application ID, every schema object,
types/nulls/limits, duplicate and dangling references, built-in grammar, single-value multiplicity,
content-or-main closure, counts/checked overflow, every row/root/image digest, timestamp round-trip,
NUL-smuggled color/icon, JPEG marker/frame/table/scan/metadata/dimension/EOF errors, every APP marker
and COM, sidecars, symlinks, hard links, source substitution, pages/index/freelist, huge counts,
text/image limits, cancellation/stall/disk-full, and every writer publication boundary. Every
contract generator pins its case ID, target rule and generated identity. At implementation
conformance, every production rejection additionally proves the active generation remains
byte-identical; the contract-only generator cannot make that runtime claim.

None of the v3 fixture, physical-oracle or capability-probe claims is satisfied by the current v2
fixture directory. The exact tracked corpus, generator/harness source and hash manifest must land
with the wire contract; implementation may not cite local `/private/tmp` artifacts as durable
evidence.

## 11. Product decision closure

Effective S1-A, M1-A and D4S-A own the shared size, taxonomy-conversion and complete-operation
semantics consumed above. PO-ratified P2-B-A through P2-G-A additionally own UUID-based taxonomy
identity and display fields, distinct NULL/empty content and answer text, Review preservation,
save-time canonical JPEG production, image-role cardinality and the five-state Backup lifecycle.
Their owning Local Library Data Contract changes become effective only when merged to `develop`;
this candidate does not replace that authority.

The product-semantic inputs required to review this exact contract candidate are closed. That does
not approve the exact DDL, reader, writer, fixture claims or runtime implementation. After the final
review-input digest is frozen and all adversarial blockers close, the exact candidate and complete
tracked evidence manifest require one separate PO ratification.
Only incorporation of that manifest digest into the owning Backup Wire Format and a later authorized
merge can make the package effective.
