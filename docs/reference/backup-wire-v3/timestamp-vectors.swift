import Foundation

private let lowerBound: Int64 = -1_000_000_000_000_000
private let upperBound: Int64 = 1_000_000_000_000_000

private func encode(_ bits: UInt64) -> Int64? {
    let seconds = Double(bitPattern: bits)
    guard seconds.isFinite else {
        return nil
    }

    let milliseconds = (seconds * 1_000).rounded(.toNearestOrEven)
    guard
        milliseconds.isFinite,
        milliseconds >= Double(Int64.min),
        milliseconds < Double(Int64.max)
    else {
        return nil
    }

    let value = Int64(milliseconds)
    guard value >= lowerBound, value <= upperBound else {
        return nil
    }
    return value
}

private let accepted: [(UInt64, Int64)] = [
    (0x3f40624dd2f1a9fc, 0),
    (0x3f589374bc6a7efa, 2),
    (0xbf40624dd2f1a9fc, 0),
    (0xbf589374bc6a7efa, -2),
    (0x426d1a94a2000004, upperBound),
    (0xc26d1a94a2000004, lowerBound),
]

private let rejected: [UInt64] = [
    0x426d1a94a2000005,
    0xc26d1a94a2000005,
    Double.infinity.bitPattern,
    (-Double.infinity).bitPattern,
    Double.nan.bitPattern,
]

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
}

private func requireReaderRoundTrip(_ milliseconds: Int64) {
    precondition(milliseconds >= lowerBound && milliseconds <= upperBound)
    let seconds = Double(milliseconds) / 1_000
    let encoded = (seconds * 1_000).rounded(.toNearestOrEven)
    precondition(
        encoded == Double(milliseconds),
        "\(milliseconds) round-tripped as \(encoded)"
    )
}

for (bits, expected) in accepted {
    let actual = encode(bits)
    precondition(actual == expected, "\(String(bits, radix: 16)): \(String(describing: actual))")
    print(String(format: "PASS 0x%016llx -> %lld", bits, expected))
}

for bits in rejected {
    precondition(encode(bits) == nil, "\(String(bits, radix: 16)) should reject")
    print(String(format: "PASS 0x%016llx -> reject", bits))
}

for milliseconds in [
    lowerBound,
    lowerBound + 1,
    lowerBound + 2,
    -1,
    0,
    1,
    upperBound - 2,
    upperBound - 1,
    upperBound,
] {
    requireReaderRoundTrip(milliseconds)
}

private let sampleCount = 1_000_007
private let span = UInt64(upperBound - lowerBound) + 1
private var generator = SplitMix64(seed: 0x534e41504452494c)
for _ in 0..<sampleCount {
    let milliseconds = lowerBound + Int64(generator.next() % span)
    requireReaderRoundTrip(milliseconds)
}
print("PASS reader-roundtrip fixed-seed samples=\(sampleCount)")
