import AutoVectorization
import AutoVectorizationSimdutf
import Benchmark

import func TestsCore.makeAlmost1MegaBytesOfRandomData

let benchmarks: @Sendable () -> Void = {
    unsafe Benchmark.defaultConfiguration.maxDuration = .seconds(5)
    unsafe Benchmark.defaultConfiguration.warmupIterations = 1000
    unsafe Benchmark.defaultConfiguration.units = [
        .instructions: .kilo,
        .cycles: .kilo,
        .throughput: .count,
    ]

    let data = makeAlmost1MegaBytesOfRandomData()
    let requiredCapacity = data.count / 3 * 4
    var output = [UInt8](repeating: 0, count: requiredCapacity)

    let naiveLoop = NaiveLoop()
    Benchmark(
        "1_Naive_Loop_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 100,
            maxIterations: 1_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe naiveLoop.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    Benchmark(
        "1_Naive_Loop_Instructions",
        configuration: .init(
            metrics: [.instructions, .cycles],
            warmupIterations: 100,
            maxIterations: 1_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe naiveLoop.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    let lookupTable = LookupTable()
    Benchmark(
        "2_Lookup_Table_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1_000,
            maxIterations: 20_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe lookupTable.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    Benchmark(
        "2_Lookup_Table_Instructions",
        configuration: .init(
            metrics: [.instructions, .cycles],
            maxIterations: 20_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe lookupTable.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    let autoVectorized = AutoVectorized()
    Benchmark(
        "3_Auto_Vectorized_Throughput",
        configuration: .init(
            metrics: [.throughput],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe autoVectorized.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    Benchmark(
        "3_Auto_Vectorized_Instructions",
        configuration: .init(
            metrics: [.instructions, .cycles],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe autoVectorized.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    let vectorizedWithLookupTable = VectorizedWithLookupTable()
    Benchmark(
        "4_Vectorized_With_Lookup_Table_Throughput",
        configuration: .init(
            metrics: [.throughput],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe vectorizedWithLookupTable.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    Benchmark(
        "4_Vectorized_With_Lookup_Table_Instructions",
        configuration: .init(
            metrics: [.instructions, .cycles],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe vectorizedWithLookupTable.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    let simdutf = Simdutf()
    Benchmark(
        "Simdutf_Throughput",
        configuration: .init(
            metrics: [.throughput],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe simdutf.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }

    Benchmark(
        "Simdutf_Instructions",
        configuration: .init(
            metrics: [.instructions, .cycles],
            maxIterations: 50_000
        )
    ) { benchmark in
        let bytes = data.span
        output.withUnsafeMutableBufferPointer { output in
            unsafe simdutf.encodeBytesToBase64(bytes: bytes, into: output)
        }
        blackHole(output)
    }
}
