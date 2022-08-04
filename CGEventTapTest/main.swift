import Foundation

struct KeyboardShortcutDefinition {
    // Set this to true to trigger the shortcut when the key is pressed. It should be set to false
    // when the shortcut should be triggered on release.
    var keyPressed: Bool
    var keyCode: KeyCode
    var pressedKeys: Set<Int64>
    
    init(keyPressed: Bool, keyCode: KeyCode, pressedKeys: Set<Int64>) {
        self.keyPressed = keyPressed
        self.keyCode = keyCode
        self.pressedKeys = pressedKeys
    }
}

var pressedKeys: Set<Int64> = []

var shortcuts: [KeyboardShortcutDefinition] = [
]

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    print("flags: \(event.flags)")
    print("event.getIntegerValueField(.keyboardEventKeycode): \(event.getIntegerValueField(.keyboardEventKeycode))")
    var ret = Unmanaged.passRetained(event) as Unmanaged<CGEvent>?
    
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    
    let controlKeys: Set<Int64> = [Int64(KeyCode.Control)]
    print("type == .keyDown: \(type == .keyDown)")
    print("pressedKeys.elementsEqual(controlKeys): \(pressedKeys.elementsEqual(controlKeys))")
    print("pressedKeys: \(pressedKeys)")
    print("controlKeys: \(controlKeys)")
    print("keyCode == Keycode.LetterC: \(keyCode == KeyCode.LetterC)")
    print("")
    if type == .keyDown && pressedKeys.elementsEqual(controlKeys) && keyCode == KeyCode.LetterC {
        let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let cmdd = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(KeyCode.LetterC), keyDown: true)
        cmdd?.flags = CGEventFlags.maskCommand
        cmdd?.post(tap: CGEventTapLocation.cghidEventTap)
        ret = nil
    }
    
    if type == .keyDown {
        pressedKeys.insert(keyCode)
    }
    
    if type == .keyUp {
        pressedKeys.remove(keyCode)
    }
    
    if type == .flagsChanged {
        if event.flags.rawValue & CGEventFlags.maskShift.rawValue != 0 {
            pressedKeys.insert(Int64(KeyCode.Shift))
        } else {
            pressedKeys.remove(Int64(KeyCode.Shift))
        }
        
        if event.flags.rawValue & CGEventFlags.maskControl.rawValue != 0 {
            pressedKeys.insert(Int64(KeyCode.Control))
        } else {
            pressedKeys.remove(Int64(KeyCode.Control))
        }
        
        if event.flags.rawValue & CGEventFlags.maskAlternate.rawValue != 0 {
            pressedKeys.insert(Int64(KeyCode.Alt))
        } else {
            pressedKeys.remove(Int64(KeyCode.Alt))
        }
        
        if event.flags.rawValue & CGEventFlags.maskCommand.rawValue != 0 {
            pressedKeys.insert(Int64(KeyCode.Windows))
        } else {
            pressedKeys.remove(Int64(KeyCode.Windows))
        }
    }
    
    print("pressedKeys (end): \(pressedKeys)")
    print("type: \(type)")
    
    // 61
   /* if [.keyDown , .keyUp].contains(type) {
        var keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == 12 {
            keyCode = 13
            return nil
        } else if keyCode == 13 {
            keyCode = 12
            
            let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)

            let cmdd = CGEvent(keyboardEventSource: src, virtualKey: 14, keyDown: true)
            cmdd?.post(tap: CGEventTapLocation.cghidEventTap)
            
            return nil

        }
        event.setIntegerValueField(.keyboardEventKeycode, value: keyCode)
        
    }*/
    return ret
}

let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
| (1 << CGEventType.flagsChanged.rawValue)// | (1 << CGEventType.scrollWheel.rawValue)
guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: myCGEventCallback,
    userInfo: nil) else {
    print("failed to create event tap")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)
CFRunLoopRun()
