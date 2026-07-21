#!/bin/sh

set -eu
umask 077

if [ "$#" -ne 2 ]; then
    printf 'usage: %s Backup.snapdrillbackup output-directory\n' "$0" >&2
    exit 2
fi

database=$1
output=$2
output_parent=$(dirname "$output")
output_name=$(basename "$output")
database_parent=$(dirname "$database")
database_name=$(basename "$database")

database_parent=$(cd "$database_parent" && pwd -P)
database="$database_parent/$database_name"
output_parent=$(cd "$output_parent" && pwd -P)
output="$output_parent/$output_name"
staging="$output_parent/.$output_name.tmp.$$"

test -f "$database"
test ! -L "$database"
test ! -e "$output"
test ! -e "$staging"
mkdir "$staging"
mkdir "$staging/images"
cd "$staging"

/usr/bin/sqlite3 -readonly "$database" <<'SQL'
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

cd "$output_parent"
test ! -e "$output"
mv "$staging" "$output"
