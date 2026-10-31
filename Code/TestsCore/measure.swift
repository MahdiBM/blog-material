@inline(always)
package func measure(
    warmupIterations: Int = 1000,
    iterations: Int,
    _ work: () -> Void
) -> Duration {
    for _ in 0..<warmupIterations {
        work()
    }

    let start = ContinuousClock.now
    for _ in 0..<iterations {
        work()
    }
    let end = ContinuousClock.now
    let duration = end - start

    return duration
}
