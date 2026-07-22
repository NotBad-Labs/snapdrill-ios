#!/usr/bin/env python3

import hashlib
import math
import struct


DOMAIN = bytes.fromhex("536e61704472696c6c204261636b757020763300")


def frame(type_byte, payload=b""):
    return bytes([type_byte]) + len(payload).to_bytes(8, "big") + payload


def null_frame():
    return frame(0x00)


def bool_frame(value):
    return frame(0x01, bytes([1 if value else 0]))


def int_frame(value):
    return frame(0x02, int(value).to_bytes(8, "big", signed=True))


def double_frame(value):
    if not math.isfinite(value):
        raise ValueError("non-finite double")
    normalized = 0.0 if value == 0.0 else value
    return frame(0x03, struct.pack(">d", normalized))


def text_frame(value):
    return null_frame() if value is None else frame(0x04, value.encode("utf-8"))


def uuid_frame(last_byte):
    return frame(0x05, bytes(15) + bytes([last_byte]))


def sha_frame(value):
    return frame(0x06, bytes.fromhex(value))


def role_frame(value):
    return frame(0x07, bytes([value]))


minimum_frames = {
    "null": null_frame().hex(),
    "int64-negative-one": int_frame(-1).hex(),
    "double-negative-zero": double_frame(-0.0).hex(),
    "utf8-a-nul-b": text_frame("A\0B").hex(),
    "utf8-empty": text_frame("").hex(),
    "role-main": role_frame(0).hex(),
}


def digest(tag, fields):
    return hashlib.sha256(DOMAIN + bytes([tag]) + b"".join(fields)).hexdigest()


dimensions = [
    (0x01, "Category", False, True, "category", 0, "folder"),
    (0x02, "Source", False, True, "source", 1, "doc"),
    (0x03, "Level", False, True, "level", 2, "chart.bar"),
    (0x04, "Tag", True, True, "tag", 3, "tag"),
    (0x05, "Empty", False, False, None, 4, "square"),
    (0x06, "Context\0上下文", True, False, None, 5, "list.bullet"),
]

values = [
    (0x11, 0x01, "Archive", "archivebox", "#3366FF", 0, 1_720_000_001_000),
    (0x12, 0x04, "重要\0Important", "star", "#FFCC00", 0, 1_720_000_002_000),
    (0x13, 0x04, "Print", "printer", "#00AA55", 1, 1_720_000_003_000),
    (0x14, 0x06, "Home", "house", "#112233", 0, 1_720_000_004_000),
]

items = [
    (0x21, "A\0B", 1_720_000_010_000, None, None, -0.0, 0, 0, "Answer only"),
    (
        0x22,
        None,
        1_720_000_020_000,
        1_720_000_030_000,
        1_720_086_400_000,
        100.0,
        7,
        3,
        None,
    ),
    (
        0x23,
        "资料 café 👩‍💻",
        1_720_000_040_000,
        None,
        1_720_172_800_000,
        -999.9,
        1,
        1,
        "答案\0Answer",
    ),
    (
        0x24,
        "No answer",
        1_720_000_050_000,
        1_720_000_060_000,
        None,
        2.5,
        30,
        8,
        None,
    ),
]

joins = [(0x22, 0x11), (0x22, 0x12), (0x22, 0x13), (0x23, 0x14)]

images = [
    (
        0x22,
        0,
        727,
        "3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d",
    ),
    (
        0x22,
        1,
        362,
        "cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414",
    ),
    (
        0x23,
        0,
        362,
        "cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414",
    ),
    (
        0x23,
        1,
        727,
        "3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d",
    ),
]


def dimension_digest(row):
    identifier, name, is_multi, is_built_in, system_key, sort_order, icon = row
    return digest(
        0x11,
        [
            uuid_frame(identifier),
            text_frame(name),
            bool_frame(is_multi),
            bool_frame(is_built_in),
            text_frame(system_key),
            int_frame(sort_order),
            text_frame(icon),
        ],
    )


def value_digest(row):
    identifier, dimension, name, icon, color, sort_order, created_at_ms = row
    return digest(
        0x12,
        [
            uuid_frame(identifier),
            uuid_frame(dimension),
            text_frame(name),
            text_frame(icon),
            text_frame(color),
            int_frame(sort_order),
            int_frame(created_at_ms),
        ],
    )


def item_digest(row):
    (
        identifier,
        content,
        created_at_ms,
        last_reviewed_at_ms,
        next_review_at_ms,
        ease_factor,
        interval_days,
        repetitions,
        answer_text,
    ) = row
    return digest(
        0x13,
        [
            uuid_frame(identifier),
            text_frame(content),
            int_frame(created_at_ms),
            null_frame() if last_reviewed_at_ms is None else int_frame(last_reviewed_at_ms),
            null_frame() if next_review_at_ms is None else int_frame(next_review_at_ms),
            double_frame(ease_factor),
            int_frame(interval_days),
            int_frame(repetitions),
            text_frame(answer_text),
        ],
    )


def join_digest(row):
    item, value = row
    return digest(0x14, [uuid_frame(item), uuid_frame(value)])


def image_digest(row):
    item, role, byte_count, content_sha256 = row
    return digest(
        0x15,
        [
            uuid_frame(item),
            role_frame(role),
            text_frame("image/jpeg"),
            int_frame(2),
            int_frame(2),
            int_frame(byte_count),
            sha_frame(content_sha256),
        ],
    )


dimension_digests = [dimension_digest(row) for row in dimensions]
value_digests = [value_digest(row) for row in values]
item_digests = [item_digest(row) for row in items]
join_digests = [join_digest(row) for row in joins]
image_digests = [image_digest(row) for row in images]

minimum_root_fields = [
    int_frame(1),
    text_frame("external-complete"),
    int_frame(3),
    int_frame(0),
    text_frame("fixture"),
    text_frame("0"),
    text_frame("sha256"),
    int_frame(0),
    int_frame(4),
    int_frame(0),
    int_frame(0),
    int_frame(0),
    int_frame(0),
]
minimum_entries = [
    bytes([0x11]) + sha_frame(value) for value in dimension_digests[:4]
]
minimum_inventory_digest = hashlib.sha256(
    DOMAIN
    + bytes([0x10])
    + b"".join(minimum_root_fields)
    + b"".join(minimum_entries)
).hexdigest()

root_fields = [
    int_frame(1),
    text_frame("external-complete"),
    int_frame(3),
    int_frame(1_720_000_000_000),
    text_frame("fixture"),
    text_frame("0"),
    text_frame("sha256"),
    int_frame(4),
    int_frame(6),
    int_frame(4),
    int_frame(4),
    int_frame(4),
    int_frame(2178),
]

entries = []
for tag, values_for_tag in [
    (0x11, dimension_digests),
    (0x12, value_digests),
    (0x13, item_digests),
    (0x14, join_digests),
    (0x15, image_digests),
]:
    entries.extend(bytes([tag]) + sha_frame(value) for value in values_for_tag)

inventory_digest = hashlib.sha256(
    DOMAIN + bytes([0x10]) + b"".join(root_fields) + b"".join(entries)
).hexdigest()

empty_item = (
    0x25,
    "",
    1_720_000_070_000,
    None,
    None,
    2.5,
    0,
    0,
    "",
)
empty_item_null_answer = empty_item[:-1] + (None,)

expected = {
    "minimum-frames": {
        "null": "000000000000000000",
        "int64-negative-one": "020000000000000008ffffffffffffffff",
        "double-negative-zero": "0300000000000000080000000000000000",
        "utf8-a-nul-b": "040000000000000003410042",
        "utf8-empty": "040000000000000000",
        "role-main": "07000000000000000100",
    },
    "dimensions": [
        "47ffb3869586b5f01d51fa6e294bc72347250454aa5aadea9dfc7878c6156530",
        "584db6973c4a076553d6e4635ec5cb94f7a9eba06dc7aa525f727d67a555bf6b",
        "c5bd86dc31d0cacfe5714bf26588371096ff1a81ecd6840a4ac5fb318ab6d180",
        "3db3d4682a5743131933c13c3354be71636c19fb0fda6f46f9a81654c577b220",
        "4865c08037f91c486ebd24f470964d609b761a490c249685b579d7485b1b000e",
        "9d6c6859a5b5dde8204433d3041cf90fa9a427bbd796d7c3ad9adf44183e85df",
    ],
    "values": [
        "060278437db774cdf3d560a6e2a8d4c7dda9005344cfe690ed4d91aef5ef576b",
        "8da487636c598a278ea4d615320a6d2dbd00f995d03afbbca045e6ef5c2ef87e",
        "c4cefb0605662e16df13db7e6c47c36d885633676cbba38a378c0f8dee42d981",
        "ef7bb81a78ff2aa153c6ceba8d3dde643f04c09883333bcc32e4451726df3f5c",
    ],
    "items": [
        "947bc0b6fb8ffc4f6e892bc405335a5b08ca87687df0807ee5c13d3ce55e9e6b",
        "11736c763bfa9aeefb484dca6a26cb3f954d63f9237853ba697011d4d26e236c",
        "5e8b45d57321290039dd8913d3d58885ba133dfcb9b87e4be0520c2c3a93d48c",
        "499623d9f742f67ddaff7683a329dbe9458c66d6db861080b454579b26f3188c",
    ],
    "joins": [
        "74e3c87d0ed7ceaad5de19c9f378863c0a7090b6e6d6b98b00d568db79746b18",
        "359ccc0737f6b18515b0f9843b1f3fd0db661d68bcaf12d25f1f44da5c63e33f",
        "812b30b2f59095d87d0a1518c84763c62a2b2df1611f416769726b3f54cdb71c",
        "343b937f9bffdbde60c4166571d3a9cef7b70a3b1cb87469624807f9867d3439",
    ],
    "images": [
        "c11326cb38150214c26b30982347da966b6e7af7c955417251ec3bfec390016d",
        "0117de3483684a01c059ef983e8943adf8b47a8676315e6955b34481c1f6a281",
        "4f8879670d82e25d7a15e40963990a8c5f976c31c7e2fce2b491b4a3a070faf4",
        "2d14b16799a793d4eff6ffe3d1c81feeaa699d5a824662387a5cca3ecf9060c8",
    ],
    "inventory": "1b9a3235235ffa39f71c7bd4d11a592ae7692ef468fecd59333ca3fc62cb872f",
    "minimum-inventory": (
        "9f87daef947811f92c6ffb71d9e84e09da78c3468a32e30ff3b79b0a599af99d"
    ),
    "empty-item": "af0acde4b154d286232862c495eaaee7b9413203e91a15a89b36bfa2d2d6ff00",
    "empty-item-null-answer": (
        "d4a37063344973e30def2a3e62f29dbfebee9c750d10e11e8b2fa3660271eaa7"
    ),
}
actual = {
    "minimum-frames": minimum_frames,
    "dimensions": dimension_digests,
    "values": value_digests,
    "items": item_digests,
    "joins": join_digests,
    "images": image_digests,
    "inventory": inventory_digest,
    "minimum-inventory": minimum_inventory_digest,
    "empty-item": item_digest(empty_item),
    "empty-item-null-answer": item_digest(empty_item_null_answer),
}
if actual != expected:
    raise AssertionError("digest known answers changed")

for label, rows, hashes in [
    ("dimensions", dimensions, dimension_digests),
    ("values", values, value_digests),
    ("items", items, item_digests),
    ("joins", joins, join_digests),
    ("images", images, image_digests),
]:
    print(label)
    for row, value in zip(rows, hashes):
        print(f"{row[0]:02x} {value}")

print(f"inventory {inventory_digest}")
print(f"minimum-inventory {minimum_inventory_digest}")
print(f"empty-item {item_digest(empty_item)}")
print(f"empty-item-null-answer {item_digest(empty_item_null_answer)}")
print("PASS digest known answers")
