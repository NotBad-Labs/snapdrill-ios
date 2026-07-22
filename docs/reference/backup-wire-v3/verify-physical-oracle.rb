#!/usr/bin/env ruby

require "digest"
require "json"
require "open3"

DB_PATH = ARGV.fetch(0, "/private/tmp/snapdrill-v3-physical-ios26.5-ms.sqlite")
EXPECTED_FILE_SHA256 = "f5568d8621c9e1c577c4972153dae75056abb4cc7e2ada996c141ae47b6b07fc"
DOMAIN = ["536e61704472696c6c204261636b757020763300"].pack("H*")

def fail_check(message)
  warn("FAIL: #{message}")
  exit(1)
end

def assert_equal(expected, actual, label)
  return if expected == actual

  fail_check("#{label}: expected #{expected.inspect}, got #{actual.inspect}")
end

def query(path, statement)
  stdout, stderr, status = Open3.capture3(
    "/usr/bin/sqlite3",
    "-readonly",
    "-json",
    path,
    statement
  )
  fail_check("sqlite query failed: #{stderr}") unless status.success?
  JSON.parse(stdout)
end

def bytes(hex)
  [hex].pack("H*")
end

def text(hex)
  value = bytes(hex).force_encoding(Encoding::UTF_8)
  fail_check("invalid UTF-8 payload") unless value.valid_encoding?
  value
end

def frame(type, payload = "".b)
  [type].pack("C") + [payload.bytesize].pack("Q>") + payload
end

def null_frame
  frame(0x00)
end

def bool_frame(value)
  frame(0x01, [value ? 1 : 0].pack("C"))
end

def int64_frame(value)
  frame(0x02, [Integer(value)].pack("q>"))
end

def double_frame(value)
  number = Float(value)
  fail_check("non-finite double") unless number.finite?
  number = 0.0 if number.zero?
  frame(0x03, [number].pack("G"))
end

def text_frame(value)
  value.nil? ? null_frame : frame(0x04, value.b)
end

def uuid_frame(value)
  assert_equal(16, value.bytesize, "UUID length")
  frame(0x05, value)
end

def digest_frame(value)
  assert_equal(32, value.bytesize, "digest length")
  frame(0x06, value)
end

def role_frame(value)
  frame(0x07, [Integer(value)].pack("C"))
end

def record_digest(tag, fields)
  Digest::SHA256.digest(DOMAIN + [tag].pack("C") + fields.join)
end

def verify_record(row, calculated, label)
  stored = bytes(row.fetch("digest_hex"))
  assert_equal(stored.unpack1("H*"), calculated.unpack1("H*"), label)
  calculated
end

file_bytes = File.binread(DB_PATH)
assert_equal(EXPECTED_FILE_SHA256, Digest::SHA256.hexdigest(file_bytes), "database SHA-256")
assert_equal(53_248, file_bytes.bytesize, "database byte count")

header = file_bytes.byteslice(0, 100)
assert_equal("SQLite format 3\0".b, header.byteslice(0, 16), "SQLite header")
page_size = header.byteslice(16, 2).unpack1("n")
page_size = 65_536 if page_size == 1
assert_equal(4_096, page_size, "page size")
assert_equal(1, header.getbyte(18), "write version")
assert_equal(1, header.getbyte(19), "read version")
assert_equal(0, header.getbyte(20), "reserved bytes")
assert_equal([64, 32, 32], header.byteslice(21, 3).bytes, "payload fractions")
assert_equal(13, header.byteslice(28, 4).unpack1("N"), "header page count")
assert_equal(0, header.byteslice(32, 4).unpack1("N"), "freelist trunk")
assert_equal(0, header.byteslice(36, 4).unpack1("N"), "freelist page count")
assert_equal(4, header.byteslice(44, 4).unpack1("N"), "schema format")
assert_equal(1, header.byteslice(56, 4).unpack1("N"), "UTF-8 encoding")
assert_equal(3, header.byteslice(60, 4).unpack1("N"), "user version")
assert_equal(707_275_168, header.byteslice(68, 4).unpack1("N"), "application ID")
assert_equal(
  header.byteslice(24, 4).unpack1("N"),
  header.byteslice(92, 4).unpack1("N"),
  "change counter/version-valid-for"
)

objects = query(
  DB_PATH,
  "SELECT type, name FROM sqlite_schema ORDER BY type, name;"
)
expected_objects = [
  ["index", "ux_category_dimension_name"],
  ["index", "ux_category_dimension_system_key"],
  ["index", "ux_category_value_dimension_name"],
  ["index", "ux_item_image_item_role"],
  ["table", "backup_root"],
  ["table", "category_dimension"],
  ["table", "category_value"],
  ["table", "item_category_value"],
  ["table", "item_image"],
  ["table", "library_item"]
]
actual_objects = objects.map { |row| [row.fetch("type"), row.fetch("name")] }
assert_equal(expected_objects, actual_objects, "allowed schema objects")

dimensions = query(
  DB_PATH,
  "SELECT hex(id) id_hex, hex(name) name_hex, is_multi_value, is_built_in, " \
    "CASE WHEN system_key IS NULL THEN NULL ELSE hex(system_key) END system_key_hex, " \
    "sort_order, hex(icon) icon_hex, hex(record_sha256) digest_hex " \
    "FROM category_dimension ORDER BY id;"
)
dimension_digests = dimensions.map do |row|
  calculated = record_digest(
    0x11,
    [
      uuid_frame(bytes(row.fetch("id_hex"))),
      text_frame(text(row.fetch("name_hex"))),
      bool_frame(row.fetch("is_multi_value") == 1),
      bool_frame(row.fetch("is_built_in") == 1),
      row["system_key_hex"].nil? ? null_frame : text_frame(text(row.fetch("system_key_hex"))),
      int64_frame(row.fetch("sort_order")),
      text_frame(text(row.fetch("icon_hex")))
    ]
  )
  verify_record(row, calculated, "dimension #{row.fetch('id_hex')}")
end

values = query(
  DB_PATH,
  "SELECT hex(id) id_hex, hex(dimension_id) dimension_id_hex, hex(name) name_hex, " \
    "hex(icon) icon_hex, hex(color_hex) color_hex_hex, sort_order, created_at_ms, " \
    "hex(record_sha256) digest_hex FROM category_value ORDER BY id;"
)
value_digests = values.map do |row|
  calculated = record_digest(
    0x12,
    [
      uuid_frame(bytes(row.fetch("id_hex"))),
      uuid_frame(bytes(row.fetch("dimension_id_hex"))),
      text_frame(text(row.fetch("name_hex"))),
      text_frame(text(row.fetch("icon_hex"))),
      text_frame(text(row.fetch("color_hex_hex"))),
      int64_frame(row.fetch("sort_order")),
      int64_frame(row.fetch("created_at_ms"))
    ]
  )
  verify_record(row, calculated, "value #{row.fetch('id_hex')}")
end

items = query(
  DB_PATH,
  "SELECT hex(id) id_hex, CASE WHEN content IS NULL THEN NULL ELSE hex(content) END content_hex, " \
    "created_at_ms, last_reviewed_at_ms, next_review_at_ms, ease_factor, interval_days, " \
    "repetitions, CASE WHEN answer_text IS NULL THEN NULL ELSE hex(answer_text) END answer_hex, " \
    "hex(record_sha256) digest_hex FROM library_item ORDER BY id;"
)
item_digests = items.map do |row|
  calculated = record_digest(
    0x13,
    [
      uuid_frame(bytes(row.fetch("id_hex"))),
      row["content_hex"].nil? ? null_frame : text_frame(text(row.fetch("content_hex"))),
      int64_frame(row.fetch("created_at_ms")),
      row["last_reviewed_at_ms"].nil? ? null_frame : int64_frame(row.fetch("last_reviewed_at_ms")),
      row["next_review_at_ms"].nil? ? null_frame : int64_frame(row.fetch("next_review_at_ms")),
      double_frame(row.fetch("ease_factor")),
      int64_frame(row.fetch("interval_days")),
      int64_frame(row.fetch("repetitions")),
      row["answer_hex"].nil? ? null_frame : text_frame(text(row.fetch("answer_hex")))
    ]
  )
  verify_record(row, calculated, "item #{row.fetch('id_hex')}")
end

joins = query(
  DB_PATH,
  "SELECT hex(item_id) item_id_hex, hex(value_id) value_id_hex, " \
    "hex(record_sha256) digest_hex FROM item_category_value ORDER BY item_id, value_id;"
)
join_digests = joins.map do |row|
  calculated = record_digest(
    0x14,
    [
      uuid_frame(bytes(row.fetch("item_id_hex"))),
      uuid_frame(bytes(row.fetch("value_id_hex")))
    ]
  )
  verify_record(
    row,
    calculated,
    "join #{row.fetch('item_id_hex')}:#{row.fetch('value_id_hex')}"
  )
end

images = query(
  DB_PATH,
  "SELECT hex(item_id) item_id_hex, role, hex(media_type) media_type_hex, pixel_width, " \
    "pixel_height, byte_count, hex(content_sha256) content_digest_hex, " \
    "hex(record_sha256) digest_hex, hex(jpeg_bytes) jpeg_hex " \
    "FROM item_image ORDER BY item_id, role;"
)
image_digests = images.map do |row|
  jpeg = bytes(row.fetch("jpeg_hex"))
  assert_equal(row.fetch("byte_count"), jpeg.bytesize, "JPEG byte count")
  assert_equal(
    row.fetch("content_digest_hex").downcase,
    Digest::SHA256.hexdigest(jpeg),
    "JPEG content digest"
  )
  assert_equal(
    "ffd8ffe000104a46494600010200000100010000",
    jpeg.byteslice(0, 20).unpack1("H*"),
    "JPEG canonical prefix"
  )
  assert_equal("ffd9", jpeg.byteslice(-2, 2).unpack1("H*"), "JPEG EOI")

  calculated = record_digest(
    0x15,
    [
      uuid_frame(bytes(row.fetch("item_id_hex"))),
      role_frame(row.fetch("role")),
      text_frame(text(row.fetch("media_type_hex"))),
      int64_frame(row.fetch("pixel_width")),
      int64_frame(row.fetch("pixel_height")),
      int64_frame(row.fetch("byte_count")),
      digest_frame(bytes(row.fetch("content_digest_hex")))
    ]
  )
  verify_record(row, calculated, "image #{row.fetch('item_id_hex')}:#{row.fetch('role')}")
end

root_rows = query(
  DB_PATH,
  "SELECT singleton, hex(artifact_kind) artifact_kind_hex, wire_version, created_at_ms, " \
    "hex(writer_marketing_version) marketing_hex, hex(writer_build) build_hex, " \
    "hex(digest_algorithm) algorithm_hex, item_count, dimension_count, value_count, " \
    "item_value_count, image_count, image_byte_count, hex(inventory_sha256) inventory_hex " \
    "FROM backup_root;"
)
assert_equal(1, root_rows.length, "backup_root row count")
root = root_rows.fetch(0)

root_frames = [
  int64_frame(root.fetch("singleton")),
  text_frame(text(root.fetch("artifact_kind_hex"))),
  int64_frame(root.fetch("wire_version")),
  int64_frame(root.fetch("created_at_ms")),
  text_frame(text(root.fetch("marketing_hex"))),
  text_frame(text(root.fetch("build_hex"))),
  text_frame(text(root.fetch("algorithm_hex"))),
  int64_frame(root.fetch("item_count")),
  int64_frame(root.fetch("dimension_count")),
  int64_frame(root.fetch("value_count")),
  int64_frame(root.fetch("item_value_count")),
  int64_frame(root.fetch("image_count")),
  int64_frame(root.fetch("image_byte_count"))
]
entries = []
[
  [0x11, dimension_digests],
  [0x12, value_digests],
  [0x13, item_digests],
  [0x14, join_digests],
  [0x15, image_digests]
].each do |tag, digests|
  digests.each do |digest|
    entries << [tag].pack("C")
    entries << digest_frame(digest)
  end
end
inventory = Digest::SHA256.digest(
  DOMAIN + [0x10].pack("C") + root_frames.join + entries.join
)
assert_equal(root.fetch("inventory_hex").downcase, inventory.unpack1("H*"), "inventory digest")

assert_equal(items.length, root.fetch("item_count"), "item count")
assert_equal(dimensions.length, root.fetch("dimension_count"), "dimension count")
assert_equal(values.length, root.fetch("value_count"), "value count")
assert_equal(joins.length, root.fetch("item_value_count"), "join count")
assert_equal(images.length, root.fetch("image_count"), "image count")
assert_equal(
  images.map { |row| row.fetch("byte_count") }.inject(0, :+),
  root.fetch("image_byte_count"),
  "image byte sum"
)

sidecars = ["-journal", "-wal", "-shm"].select { |suffix| File.exist?(DB_PATH + suffix) }
assert_equal([], sidecars, "SQLite sidecars")

empty_item_fields = [
  uuid_frame(bytes("00000000000000000000000000000025")),
  text_frame("".b),
  int64_frame(1_720_000_070_000),
  null_frame,
  null_frame,
  double_frame(2.5),
  int64_frame(0),
  int64_frame(0)
]
empty_item_digest = record_digest(
  0x13,
  empty_item_fields + [text_frame("".b)]
)
null_answer_digest = record_digest(
  0x13,
  empty_item_fields + [null_frame]
)
assert_equal(
  "af0acde4b154d286232862c495eaaee7b9413203e91a15a89b36bfa2d2d6ff00",
  empty_item_digest.unpack1("H*"),
  "Ruby empty-item digest"
)
assert_equal(
  "d4a37063344973e30def2a3e62f29dbfebee9c750d10e11e8b2fa3660271eaa7",
  null_answer_digest.unpack1("H*"),
  "Ruby NULL-answer digest"
)
fail_check("empty UTF-8 collapsed into NULL") if empty_item_digest == null_answer_digest

puts("PASS database_sha256=#{Digest::SHA256.hexdigest(file_bytes)}")
puts("PASS inventory_sha256=#{inventory.unpack1('H*')}")
puts("PASS Ruby empty/NULL item digest pair")
puts(
  "PASS counts=#{items.length}/#{dimensions.length}/#{values.length}/" \
    "#{joins.length}/#{images.length}/#{root.fetch('image_byte_count')}"
)
