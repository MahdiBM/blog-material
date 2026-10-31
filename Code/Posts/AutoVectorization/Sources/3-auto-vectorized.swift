package struct AutoVectorized {
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

            let byte1 = unsafe bytes[unchecked: index]
            let byte2 = unsafe bytes[unchecked: index + 1]
            let byte3 = unsafe bytes[unchecked: index + 2]

            let base64Values = bytesToBase64(byte1, byte2, byte3)

            let encodedYellow = base64ValueToASCII_branchless(base64Values.yellow)
            let encodedGreen = base64ValueToASCII_branchless(base64Values.green)
            let encodedBlue = base64ValueToASCII_branchless(base64Values.blue)
            let encodedPurple = base64ValueToASCII_branchless(base64Values.purple)

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

    /// Converts a Base64 value to its corresponding ASCII code based on the following table.
    /// | Base64 Value     | 0 ... 25     | 26 ... 51     | 52 ... 61    | 62  | 63  |
    /// | ASCII Characters | A ... Z      | a ... z       | 0 ... 9      |  +  |  /  |
    /// | ASCII Codes      | 65 ... 90    | 97 ... 122    | 48 ... 57    | 43  | 47  |
    /// | Formula          | +65 (65 - 0) | +71 (97 - 26) | -4 (48 - 52) |  -  |  -  |
    /// Requires: `value` must be in range of 0 to 63. Higher values are invalid in Base64 encoding.
    func base64ValueToASCII_branchless(_ value: UInt8) -> UInt8 {
        let compare25 = value <= 25
        let compare51 = value <= 51
        let compare61 = value <= 61

        let plus65 = value &+ 65
        let plus71 = value &+ 71
        let minus4 = value &- 4

        if compare25 { return plus65 }
        if compare51 { return plus71 }
        if compare61 { return minus4 }
        if value == 62 { return 43 }
        // If the value is none of the above, it must be 63 then.
        return 47
    }

    /// Converts a Base64 value to its corresponding ASCII code based on the following table.
    /// | Base64 Value | 0 ... 25     | 26 ... 51     | 52 ... 61    | 62  | 63  |
    /// | ASCII Codes  | 65 ... 90    | 97 ... 122    | 48 ... 57    | 43  | 47  |
    /// | Formula      | +65 (65 - 0) | +71 (97 - 26) | -4 (48 - 52) |  -  |  -  |
    /// Requires: `value` must be in range of 0 to 63. Higher values are invalid in Base64 encoding.
    func base64ValueToASCII_branchless_v1(_ value: UInt8) -> UInt8 {
        let compare25 = value <= 25
        let compare51 = value <= 51
        let compare61 = value <= 61
        let compare62 = value == 62

        let plus65 = value &+ 65
        let plus71 = value &+ 71
        let minus4 = value &- 4

        if compare25 { return plus65 }
        if compare51 { return plus71 }
        if compare61 { return minus4 }
        if compare62 { return 43 }
        // If the value is none of the above, it must be 63 then.
        return 47
    }
}
