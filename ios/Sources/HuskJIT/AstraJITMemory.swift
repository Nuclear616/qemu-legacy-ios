import Foundation

@_silgen_name("qemu_podium_jit_prepare")
private func qemu_podium_jit_prepare() -> Int32

/// Must be called while StikJIT's helper is attached: the first allocation
/// sends the TXM breakpoint requests that the helper services, then detaches.
enum AstraJITMemory {
    static func prepareWhileDebuggerAttached() -> Bool {
        let mode = qemu_podium_jit_prepare()
        return mode == 1 || mode == 2
    }
}
