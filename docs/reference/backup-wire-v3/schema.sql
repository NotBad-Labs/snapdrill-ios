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
