// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "blog-material",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/swift-dns/swift-vectorization.git", exact: "1.0.0-alpha.12"),
        .package(url: "https://github.com/MahdiBM/benchmark.git", branch: "mmbm-more-hardware-counters"),
    ],
    targets: [
        .target(
            name: "AutoVectorization",
            dependencies: [.product(name: "Vectorization", package: "swift-vectorization")],
            path: "Code/Posts/AutoVectorization/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AutoVectorizationTests",
            dependencies: ["AutoVectorization", "AutoVectorizationSimdutf", "TestsCore"],
            path: "Code/Posts/AutoVectorization/Tests",
            swiftSettings: swiftSettings + [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "AutoVectorizationBenchs",
            dependencies: [
                "AutoVectorization",
                "AutoVectorizationSimdutf",
                "TestsCore",
                .product(name: "Benchmark", package: "benchmark"),
            ],
            path: "Code/Posts/AutoVectorization/Benchmarks/Base64",
            swiftSettings: swiftSettings + [.interoperabilityMode(.Cxx)],
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
        .target(
            name: "AutoVectorizationSimdutf",
            dependencies: ["CSimdutf"],
            path: "Code/Posts/AutoVectorization/Simdutf",
            swiftSettings: swiftSettings + [.interoperabilityMode(.Cxx)]
        ),
        .target(
            name: "CSimdutf",
            path: "Code/Posts/AutoVectorization/CSimdutf",
            exclude: ["LICENSE-APACHE", "LICENSE-MIT"]
        ),
        .target(
            name: "TestsCore",
            path: "Code/TestsCore",
            swiftSettings: swiftSettings
        ),
    ],
    cxxLanguageStandard: .cxx17
)

var swiftSettings: [SwiftSetting] {
    [
        .swiftLanguageMode(.v6),
        .strictMemorySafety(),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
    ]
}
