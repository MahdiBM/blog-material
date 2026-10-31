import AutoVectorization
import AutoVectorizationSimdutf
import Foundation
import Testing
import TestsCore

@Suite
struct CrossCheckTests {
    @Test func `cross check "(1) naive loop" and foundation for correctness`() {
        let impl = NaiveLoop()
        for _ in 0..<100 {
            let data = makeAlmost1MegaBytesOfRandomData()
            let requiredCapacity = data.span.count / 3 * 4
            let implEncoded = unsafe [UInt8](unsafeUninitializedCapacity: requiredCapacity) {
                buffer, initializedCount in
                unsafe impl.encodeBytesToBase64(bytes: data.span, into: buffer)
                initializedCount = requiredCapacity
            }
            let foundationEncoded = Data(data).base64EncodedData()
            #expect(Data(implEncoded) == foundationEncoded)
        }
    }

    @Test func `cross check "(2) lookup table" and foundation for correctness`() {
        let impl = LookupTable()
        for _ in 0..<100 {
            let data = makeAlmost1MegaBytesOfRandomData()
            let requiredCapacity = data.span.count / 3 * 4
            let implEncoded = unsafe [UInt8](unsafeUninitializedCapacity: requiredCapacity) {
                buffer, initializedCount in
                unsafe impl.encodeBytesToBase64(bytes: data.span, into: buffer)
                initializedCount = requiredCapacity
            }
            let foundationEncoded = Data(data).base64EncodedData()
            #expect(Data(implEncoded) == foundationEncoded)
        }
    }

    @Test func `cross check "(3) auto vectorized" and foundation for correctness`() {
        let impl = AutoVectorized()
        for _ in 0..<100 {
            let data = makeAlmost1MegaBytesOfRandomData()
            let requiredCapacity = data.span.count / 3 * 4
            let implEncoded = unsafe [UInt8](unsafeUninitializedCapacity: requiredCapacity) {
                buffer, initializedCount in
                unsafe impl.encodeBytesToBase64(bytes: data.span, into: buffer)
                initializedCount = requiredCapacity
            }
            let foundationEncoded = Data(data).base64EncodedData()
            #expect(Data(implEncoded) == foundationEncoded)
        }
    }

    @Test func `cross check "(4) vectorized with lookup table" and foundation for correctness`() {
        let impl = VectorizedWithLookupTable()
        for _ in 0..<100 {
            let data = makeAlmost1MegaBytesOfRandomData()
            let requiredCapacity = data.span.count / 3 * 4
            let implEncoded = unsafe [UInt8](unsafeUninitializedCapacity: requiredCapacity) {
                buffer, initializedCount in
                unsafe impl.encodeBytesToBase64(bytes: data.span, into: buffer)
                initializedCount = requiredCapacity
            }
            let foundationEncoded = Data(data).base64EncodedData()
            #expect(Data(implEncoded) == foundationEncoded)
        }
    }

    @Test func `cross check simdutf and foundation for correctness`() {
        let impl = Simdutf()
        for _ in 0..<100 {
            let data = makeAlmost1MegaBytesOfRandomData()
            let requiredCapacity = data.span.count / 3 * 4
            let implEncoded = unsafe [UInt8](unsafeUninitializedCapacity: requiredCapacity) {
                buffer, initializedCount in
                unsafe impl.encodeBytesToBase64(bytes: data.span, into: buffer)
                initializedCount = requiredCapacity
            }
            let foundationEncoded = Data(data).base64EncodedData()
            #expect(Data(implEncoded) == foundationEncoded)
        }
    }
}
