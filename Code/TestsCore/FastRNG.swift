import Synchronization

struct FastRNG {
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15

    mutating func next() -> UInt64 {
        self.state ^= self.state &<< 13
        self.state ^= self.state &>> 7
        self.state ^= self.state &<< 17
        return self.state
    }
}

private let fastRng: Mutex<FastRNG> = Mutex(FastRNG())

/// Makes 999_999 bytes of (deterministically) random data.
/// 999_999 is chosen because it's divisible by 3.
package func makeAlmost1MegaBytesOfRandomData() -> [UInt8] {
    fastRng.withLock { rng in
        [UInt8](capacity: 999_999) { output in
            for _ in 0..<999_999 {
                output.append(UInt8(truncatingIfNeeded: rng.next()))
            }
        }
    }
}
