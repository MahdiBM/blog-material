import CSimdutf

package struct Simdutf {
    package init() {}

    /// Generate Base64 encoded bytes from the given input bytes, using simdutf.
    /// Writes to `output`.
    /// Requires:
    ///   - `bytes.count` must be a multiple of 3.
    ///   - `output.count` must be at least `bytes.count / 3 * 4`.
    package func encodeBytesToBase64(
        bytes: Span<UInt8>, into output: UnsafeMutableBufferPointer<UInt8>
    ) {
        precondition(bytes.count % 3 == 0, "Bytes count needs to be a multiple of 3")
        precondition(output.count >= bytes.count / 3 * 4, "Insufficient output capacity")

        bytes.withUnsafeBufferPointer { input in
            unsafe input.withMemoryRebound(to: CChar.self) { input in
                unsafe output.withMemoryRebound(to: CChar.self) { output in
                    _ = unsafe simdutf.binary_to_base64(
                        input.baseAddress,
                        input.count,
                        output.baseAddress,
                        simdutf.base64_default
                    )
                }
            }
        }
    }
}
