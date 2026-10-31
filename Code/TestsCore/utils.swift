/// Stops the compiler from optimizing away the value.
@inline(never) @_optimize(none)
package func blackHole(_ value: Any) {}
