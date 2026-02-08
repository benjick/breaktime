import Foundation

struct ScreenLockService {
    static func lockScreen() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        guard libHandle != nil else { return }
        guard let sym = dlsym(libHandle, "SACLockScreenImmediate") else { return }
        typealias LockFunction = @convention(c) () -> Void
        let lock = unsafeBitCast(sym, to: LockFunction.self)
        lock()
    }
}
