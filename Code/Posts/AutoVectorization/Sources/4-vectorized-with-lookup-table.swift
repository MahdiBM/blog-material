import Vectorization

package struct VectorizedWithLookupTable {
    package init() {}

    /// Generate Base64 encoded bytes from the given input bytes.
    /// Writes to `output`.
    /// Requires:
    ///   - `bytes.count` must be a multiple of 3.
    ///   - `output.count` must be at least `bytes.count / 3 * 4`.
    package func encodeBytesToBase64(
        bytes: Span<UInt8>,
        into output: UnsafeMutableBufferPointer<UInt8>
    ) {
        precondition(bytes.count % 3 == 0, "Bytes count needs to be a multiple of 3")
        precondition(output.count >= bytes.count / 3 * 4, "Insufficient output capacity")

        let bytesPerIteration = SIMDUInt8.laneCount * 3
        let outputBytesPerIteration = SIMDUInt8.laneCount * 4
        let iterations = bytes.count / bytesPerIteration

        withAlignedBase64Lut { base64Lut in
            for iteration in 0..<iterations {
                let index = iteration * bytesPerIteration
                let outputIndex = iteration * outputBytesPerIteration

                var byte1 = SIMDUInt8.zero()
                var byte2 = SIMDUInt8.zero()
                var byte3 = SIMDUInt8.zero()
                SIMDUInt8.loadInterleaved3(
                    from: bytes.extracting(droppingFirst: index), &byte1, &byte2, &byte3
                )

                let base64Values = bytesToBase64_vectorized(byte1, byte2, byte3)

                let encodedYellow = base64ValueToASCII_vectorizedLookupTable(
                    base64Values.yellow, base64Lut: base64Lut
                )
                let encodedGreen = base64ValueToASCII_vectorizedLookupTable(
                    base64Values.green, base64Lut: base64Lut
                )
                let encodedBlue = base64ValueToASCII_vectorizedLookupTable(
                    base64Values.blue, base64Lut: base64Lut
                )
                let encodedPurple = base64ValueToASCII_vectorizedLookupTable(
                    base64Values.purple, base64Lut: base64Lut
                )

                unsafe SIMDUInt8.storeInterleaved4(
                    encodedYellow, encodedGreen, encodedBlue, encodedPurple,
                    to: output.baseAddress.unsafelyUnwrapped + outputIndex
                )
            }
        }

        /// The last bytes that weren't enough for a full `bytesPerIteration` iteration.
        let remainingBytes = bytes.extracting(droppingFirst: iterations * bytesPerIteration)
        let remainingOutput = unsafe UnsafeMutableBufferPointer(
            rebasing: output[(iterations * outputBytesPerIteration)...]
        )
        unsafe AutoVectorized().encodeBytesToBase64(bytes: remainingBytes, into: remainingOutput)
    }

    /// Receives 3 vectors of bytes, returns 4 vectors of base-64 values, each in range of 0 to 63.
    func bytesToBase64_vectorized(
        _ byte1: SIMDUInt8.Vector,
        _ byte2: SIMDUInt8.Vector,
        _ byte3: SIMDUInt8.Vector
    ) -> (
        yellow: SIMDUInt8.Vector,
        green: SIMDUInt8.Vector,
        blue: SIMDUInt8.Vector,
        purple: SIMDUInt8.Vector
    ) {
        let yellow = SIMDUInt8.shiftedRight(byte1, by: 2)
        // 0x03 == 0b0000_0011, 0x0F == 0b0000_1111
        let green = SIMDUInt8.bitwiseOr(
            SIMDUInt8.shiftedLeft(
                SIMDUInt8.bitwiseAnd(byte1, SIMDUInt8.repeating(0x03)), by: 4
            ),
            SIMDUInt8.shiftedRight(byte2, by: 4)
        )
        let blue = SIMDUInt8.bitwiseOr(
            SIMDUInt8.shiftedLeft(
                SIMDUInt8.bitwiseAnd(byte2, SIMDUInt8.repeating(0x0F)), by: 2
            ),
            SIMDUInt8.shiftedRight(byte3, by: 6)
        )
        // 0x3F == 0b0011_1111
        let purple = SIMDUInt8.bitwiseAnd(byte3, SIMDUInt8.repeating(0x3F))

        return (yellow, green, blue, purple)
    }

    /// The Base64 Lookup Table (LUT) as an inline array.
    static let base64Lut: InlineArray<64, UInt8> = [
        UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "D"),
        UInt8(ascii: "E"), UInt8(ascii: "F"), UInt8(ascii: "G"), UInt8(ascii: "H"),
        UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"), UInt8(ascii: "L"),
        UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"), UInt8(ascii: "P"),
        UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "T"),
        UInt8(ascii: "U"), UInt8(ascii: "V"), UInt8(ascii: "W"), UInt8(ascii: "X"),
        UInt8(ascii: "Y"), UInt8(ascii: "Z"), UInt8(ascii: "a"), UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"),
        UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"), UInt8(ascii: "j"),
        UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "n"),
        UInt8(ascii: "o"), UInt8(ascii: "p"), UInt8(ascii: "q"), UInt8(ascii: "r"),
        UInt8(ascii: "s"), UInt8(ascii: "t"), UInt8(ascii: "u"), UInt8(ascii: "v"),
        UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"), UInt8(ascii: "z"),
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "+"), UInt8(ascii: "/"),
    ]

    /// Calls `body` with `base64Lut` copied into a 64-byte aligned buffer, as `SIMDUInt8.lookup64` requires.
    func withAlignedBase64Lut<Result>(_ body: (Span<UInt8>) -> Result) -> Result {
        withUnsafeTemporaryAllocation(byteCount: 64, alignment: 64) { buffer in
            let table = Self.base64Lut.span.withUnsafeBytes { lut in
                unsafe buffer.initializeMemory(as: UInt8.self, fromContentsOf: lut)
            }
            return body(unsafe table.span)
        }
    }

    /// Converts Base64 values to their corresponding ASCII codes using a 64-byte lookup table.
    /// | Base64 Value     | 0 ... 25     | 26 ... 51     | 52 ... 61    | 62  | 63  |
    /// | ASCII Characters | A ... Z      | a ... z       | 0 ... 9      |  +  |  /  |
    /// | ASCII Codes      | 65 ... 90    | 97 ... 122    | 48 ... 57    | 43  | 47  |
    /// Requires: `values` must be in range of 0 to 63. Higher values are invalid in Base64 encoding.
    func base64ValueToASCII_vectorizedLookupTable(
        _ values: SIMDUInt8.Vector,
        base64Lut: Span<UInt8>
    ) -> SIMDUInt8.Vector {
        unsafe SIMDUInt8.lookup64(at: values, fromUnchecked: base64Lut)
    }
}
