import AppKit
import AVFoundation
import CoreAudio

@MainActor
class ExceptionMonitor {
    private weak var appState: AppState?
    private var pollTimer: Timer?
    private var wasExceptionActive = false

    /// Human-readable reason for the current exception (e.g. "microphone", "Zoom (opened)")
    private(set) var activeReason: String?

    var onExceptionStateChanged: ((Bool) -> Void)?

    func start(appState: AppState) {
        self.appState = appState

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func poll() {
        guard let appState = appState else { return }

        var isActive = false
        var reason: String?

        // Check automatic exceptions
        if appState.config.autoExceptionMicrophone && isMicrophoneInUse() {
            isActive = true
            reason = "microphone"
        }

        if appState.config.autoExceptionScreenSharing && isScreenSharingActive() {
            isActive = true
            reason = reason ?? "screen sharing"
        }

        // Check per-app rules
        for rule in appState.config.exceptionRules {
            if isAppExceptionActive(rule: rule) {
                isActive = true
                reason = reason ?? "\(rule.appName) (\(rule.triggerMode.rawValue))"
                break
            }
        }

        appState.exceptionsActive = isActive
        appState.exceptionReason = reason
        activeReason = reason

        // Detect state changes
        if wasExceptionActive && !isActive {
            onExceptionStateChanged?(false)
        } else if !wasExceptionActive && isActive {
            onExceptionStateChanged?(true)
        }

        wasExceptionActive = isActive
    }

    private func isMicrophoneInUse() -> Bool {
        // Query CoreAudio to check if any audio input device is actively running
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress, 0, nil, &dataSize
        ) == noErr else { return false }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        guard deviceCount > 0 else { return false }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress, 0, nil, &dataSize, &deviceIDs
        ) == noErr else { return false }

        for deviceID in deviceIDs {
            // Check if device has input streams
            var inputStreamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(
                deviceID, &inputStreamAddress, 0, nil, &streamSize
            ) == noErr, streamSize > 0 else { continue }

            // Check if this input device is running somewhere
            var isRunning: UInt32 = 0
            var runningSize = UInt32(MemoryLayout<UInt32>.size)
            var runningAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            if AudioObjectGetPropertyData(
                deviceID, &runningAddress, 0, nil, &runningSize, &isRunning
            ) == noErr, isRunning != 0 {
                return true
            }
        }
        return false
    }

    private func isScreenSharingActive() -> Bool {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        let screenSharingBundleIDs: Set<String> = [
            "com.apple.screensharing",
            "com.apple.ScreenSharing",
        ]

        for app in runningApps {
            if let bundleId = app.bundleIdentifier, screenSharingBundleIDs.contains(bundleId) {
                return true
            }
        }
        return false
    }

    private func isAppExceptionActive(rule: ExceptionRule) -> Bool {
        let workspace = NSWorkspace.shared

        switch rule.triggerMode {
        case .focused:
            return workspace.frontmostApplication?.bundleIdentifier == rule.bundleIdentifier

        case .opened:
            return workspace.runningApplications.contains {
                $0.bundleIdentifier == rule.bundleIdentifier
            }
        }
    }
}
