import AppKit
import Carbon

/// Registers one discrete system hot key instead of observing every key press.
/// This lets Command-Shift-A work before Accessibility permission is granted.
final class HotKeyManager {
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x5154_524E, id: 1) // "QTRN"

    func start() {
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return noErr }

            var receivedID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &receivedID
            )
            guard status == noErr,
                  receivedID.id == 1,
                  receivedID.signature == 0x5154_524E else { return noErr }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onTrigger?()
            return noErr
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            context,
            &eventHandlerRef
        )

        RegisterEventHotKey(
            UInt32(kVK_ANSI_A),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    deinit { stop() }
}
