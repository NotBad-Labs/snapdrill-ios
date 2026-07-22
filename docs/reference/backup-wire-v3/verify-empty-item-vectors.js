#!/usr/bin/env node

"use strict";

const crypto = require("crypto");

const DOMAIN = Buffer.from("536e61704472696c6c204261636b757020763300", "hex");
const EXPECTED_EMPTY =
  "af0acde4b154d286232862c495eaaee7b9413203e91a15a89b36bfa2d2d6ff00";
const EXPECTED_NULL_ANSWER =
  "d4a37063344973e30def2a3e62f29dbfebee9c750d10e11e8b2fa3660271eaa7";
const EXPECTED_MINIMUM_INVENTORY =
  "9f87daef947811f92c6ffb71d9e84e09da78c3468a32e30ff3b79b0a599af99d";

function frame(type, payload = Buffer.alloc(0)) {
  const header = Buffer.alloc(9);
  header.writeUInt8(type, 0);
  header.writeBigUInt64BE(BigInt(payload.length), 1);
  return Buffer.concat([header, payload]);
}

function nullFrame() {
  return frame(0x00);
}

function boolFrame(value) {
  return frame(0x01, Buffer.from([value ? 1 : 0]));
}

function intFrame(value) {
  const payload = Buffer.alloc(8);
  payload.writeBigInt64BE(BigInt(value));
  return frame(0x02, payload);
}

function doubleFrame(value) {
  if (!Number.isFinite(value)) {
    throw new Error("non-finite double");
  }
  const payload = Buffer.alloc(8);
  payload.writeDoubleBE(Object.is(value, -0) ? 0 : value);
  return frame(0x03, payload);
}

function textFrame(value) {
  return value === null ? nullFrame() : frame(0x04, Buffer.from(value, "utf8"));
}

function uuidFrame(lastByte) {
  const payload = Buffer.alloc(16);
  payload.writeUInt8(lastByte, 15);
  return frame(0x05, payload);
}

function shaFrame(value) {
  return frame(0x06, Buffer.from(value, "hex"));
}

function roleFrame(value) {
  return frame(0x07, Buffer.from([value]));
}

function recordDigest(tag, fields) {
  return crypto
    .createHash("sha256")
    .update(Buffer.concat([DOMAIN, Buffer.from([tag]), ...fields]))
    .digest("hex");
}

function itemDigest(answerText) {
  const fields = [
    uuidFrame(0x25),
    textFrame(""),
    intFrame(1720000070000n),
    nullFrame(),
    nullFrame(),
    doubleFrame(2.5),
    intFrame(0n),
    intFrame(0n),
    textFrame(answerText),
  ];
  return recordDigest(0x13, fields);
}

function dimensionDigest(row) {
  const [identifier, name, isMulti, isBuiltIn, systemKey, sortOrder, icon] = row;
  return recordDigest(0x11, [
    uuidFrame(identifier),
    textFrame(name),
    boolFrame(isMulti),
    boolFrame(isBuiltIn),
    textFrame(systemKey),
    intFrame(sortOrder),
    textFrame(icon),
  ]);
}

const expectedFrames = {
  null: "000000000000000000",
  int64NegativeOne: "020000000000000008ffffffffffffffff",
  doubleNegativeZero: "0300000000000000080000000000000000",
  utf8ANulB: "040000000000000003410042",
  utf8Empty: "040000000000000000",
  roleMain: "07000000000000000100",
};
const actualFrames = {
  null: nullFrame().toString("hex"),
  int64NegativeOne: intFrame(-1n).toString("hex"),
  doubleNegativeZero: doubleFrame(-0).toString("hex"),
  utf8ANulB: textFrame("A\0B").toString("hex"),
  utf8Empty: textFrame("").toString("hex"),
  roleMain: roleFrame(0).toString("hex"),
};
if (JSON.stringify(actualFrames) !== JSON.stringify(expectedFrames)) {
  throw new Error(`minimum frame mismatch: ${JSON.stringify(actualFrames)}`);
}

const minimumDimensions = [
  [0x01, "Category", false, true, "category", 0n, "folder"],
  [0x02, "Source", false, true, "source", 1n, "doc"],
  [0x03, "Level", false, true, "level", 2n, "chart.bar"],
  [0x04, "Tag", true, true, "tag", 3n, "tag"],
];
const minimumDimensionDigests = minimumDimensions.map(dimensionDigest);
const minimumRootFields = [
  intFrame(1n),
  textFrame("external-complete"),
  intFrame(3n),
  intFrame(0n),
  textFrame("fixture"),
  textFrame("0"),
  textFrame("sha256"),
  intFrame(0n),
  intFrame(4n),
  intFrame(0n),
  intFrame(0n),
  intFrame(0n),
  intFrame(0n),
];
const minimumEntries = minimumDimensionDigests.map((value) =>
  Buffer.concat([Buffer.from([0x11]), shaFrame(value)]),
);
const minimumInventory = crypto
  .createHash("sha256")
  .update(
    Buffer.concat([
      DOMAIN,
      Buffer.from([0x10]),
      ...minimumRootFields,
      ...minimumEntries,
    ]),
  )
  .digest("hex");
if (minimumInventory !== EXPECTED_MINIMUM_INVENTORY) {
  throw new Error(`minimum inventory mismatch: ${minimumInventory}`);
}

const empty = itemDigest("");
const nullAnswer = itemDigest(null);
if (empty !== EXPECTED_EMPTY || nullAnswer !== EXPECTED_NULL_ANSWER) {
  throw new Error(
    `empty vector mismatch: empty=${empty} nullAnswer=${nullAnswer}`,
  );
}
if (empty === nullAnswer) {
  throw new Error("empty UTF-8 collapsed into NULL");
}

console.log(`PASS Node empty-item=${empty}`);
console.log(`PASS Node empty-item-null-answer=${nullAnswer}`);
console.log(`PASS Node minimum-inventory=${minimumInventory}`);
console.log("PASS Node minimum framing vectors");
