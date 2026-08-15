import Carbon
import Foundation

final class HotKeyManager {
    private var toggleRef: EventHotKeyRef?
    private var peekRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private(set) var registrationSucceeded = true

    var onToggle: (() -> Void)?
    var onPeekChanged: ((Bool) -> Void)?

    init() {
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(context).takeUnretainedValue()
                return manager.handle(event)
            },
            eventTypes.count,
            &eventTypes,
            pointer,
            &handlerRef
        )

        let modifiers = UInt32(cmdKey | optionKey)
        let toggleStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_G),
            modifiers,
            EventHotKeyID(signature: Self.signature, id: 1),
            GetApplicationEventTarget(),
            0,
            &toggleRef
        )
        let peekStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            modifiers,
            EventHotKeyID(signature: Self.signature, id: 2),
            GetApplicationEventTarget(),
            0,
            &peekRef
        )
        registrationSucceeded = handlerStatus == noErr
            && toggleStatus == noErr
            && peekStatus == noErr
    }

    deinit {
        if let toggleRef { UnregisterEventHotKey(toggleRef) }
        if let peekRef { UnregisterEventHotKey(peekRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr, hotKeyID.signature == Self.signature else { return status }

        let kind = GetEventKind(event)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch hotKeyID.id {
            case 1 where kind == UInt32(kEventHotKeyPressed): self.onToggle?()
            case 2: self.onPeekChanged?(kind == UInt32(kEventHotKeyPressed))
            default: break
            }
        }
        return noErr
    }

    private static let signature: OSType = 0x4952444B // 'IRDK'
}
