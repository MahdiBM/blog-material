package struct LookupTable {
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

        let triples = bytes.count / 3

        for triple in 0..<triples {
            let index = triple * 3
            let outputIndex = triple * 4

            let byte1 = bytes[index]
            let byte2 = bytes[index + 1]
            let byte3 = bytes[index + 2]

            let base64Values = bytesToBase64(byte1, byte2, byte3)

            let encodedYellow = base64ValueToASCII_lookupTable(base64Values.yellow)
            let encodedGreen = base64ValueToASCII_lookupTable(base64Values.green)
            let encodedBlue = base64ValueToASCII_lookupTable(base64Values.blue)
            let encodedPurple = base64ValueToASCII_lookupTable(base64Values.purple)

            unsafe output[outputIndex] = encodedYellow
            unsafe output[outputIndex + 1] = encodedGreen
            unsafe output[outputIndex + 2] = encodedBlue
            unsafe output[outputIndex + 3] = encodedPurple
        }
    }

    /// Receives 3 bytes, returns 4 base-64 values, each in range of 0 to 63.
    func bytesToBase64(
        _ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8
    ) -> (yellow: UInt8, green: UInt8, blue: UInt8, purple: UInt8) {
        let yellow = byte1 >> 2
        // 0x03 == 0b0000_0011, 0x0F == 0b0000_1111
        let green = ((byte1 & 0x03) << 4) | (byte2 >> 4)
        let blue = ((byte2 & 0x0F) << 2) | (byte3 >> 6)
        // 0x3F == 0b0011_1111
        let purple = byte3 & 0x3F

        return (yellow, green, blue, purple)
    }

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

    /// Converts a Base64 value to its corresponding ASCII code using a lookup table.
    /// | Base64 Value     | 0 ... 25     | 26 ... 51     | 52 ... 61    | 62  | 63  |
    /// | ASCII Characters | A ... Z      | a ... z       | 0 ... 9      |  +  |  /  |
    /// | ASCII Codes      | 65 ... 90    | 97 ... 122    | 48 ... 57    | 43  | 47  |
    /// | Formula          | +65 (65 - 0) | +71 (97 - 26) | -4 (48 - 52) |  -  |  -  |
    /// Requires: `value` must be in range of 0 to 63. Higher values are invalid in Base64 encoding.
    func base64ValueToASCII_lookupTable(_ value: UInt8) -> UInt8 {
        return Self.base64Lut[Int(value)]
    }
}
