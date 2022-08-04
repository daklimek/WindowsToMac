import Foundation
import Cocoa

struct KeyboardCommand {
    // Set this to true to trigger the shortcut when the key is pressed. It should be set to false
    // when the shortcut should be triggered on release.
    var keyPressed: Bool
    var keyCode: Int64
    var pressedKeys: Set<Int64>
    
    init(keyPressed: Bool, keyCode: Int64, pressedKeys: Set<Int64>) {
        self.keyPressed = keyPressed
        self.keyCode = keyCode
        self.pressedKeys = pressedKeys
    }
    
    func getFlagsFromPressedKeys() -> CGEventFlags {
        
        
        var result = UInt64(0)
        
        if self.pressedKeys.contains(Int64(KeyCode.Shift)) {
            result |= CGEventFlags.maskShift.rawValue
        }
        
        if self.pressedKeys.contains(Int64(KeyCode.Control)) {
            result |= CGEventFlags.maskControl.rawValue
        }
        
        if self.pressedKeys.contains(Int64(KeyCode.Windows)) {
            result |= CGEventFlags.maskCommand.rawValue
        }
        
        if self.pressedKeys.contains(Int64(KeyCode.Alt)) {
            result |= CGEventFlags.maskAlternate.rawValue
        }
        
        
        return CGEventFlags(rawValue: result)
    }
}

struct KeyboardShortcutDefinition {
    var fromKey: KeyboardCommand
    var toKey: KeyboardCommand
    var applications: Set<String>
    
    init(fromKey: KeyboardCommand, toKey: KeyboardCommand, applications: Set<String>) {
        self.fromKey = fromKey
        self.toKey = toKey
        self.applications = applications
    }
}

var pressedKeys: Set<Int64> = []

var shortcuts: [KeyboardShortcutDefinition] = [
    KeyboardShortcutDefinition(
        fromKey: KeyboardCommand(keyPressed: true, keyCode: Int64(KeyCode.LetterX), pressedKeys:[Int64(KeyCode.Control)]),
        toKey: KeyboardCommand(keyPressed: true, keyCode: Int64(KeyCode.LetterC), pressedKeys:[Int64(KeyCode.Control)]),
        applications: ["Terminal"]
    )
]


// Control + <Letter> -> WindowsKey + <Letter>
for letter in letters {
    shortcuts.append(
        KeyboardShortcutDefinition(
            fromKey: KeyboardCommand(keyPressed: true, keyCode: Int64(letter), pressedKeys:[Int64(KeyCode.Control)]),
            toKey: KeyboardCommand(keyPressed: true, keyCode: Int64(letter), pressedKeys:[Int64(KeyCode.Windows)]),
            applications: []
    ))
}

// Control + Shift + <Arrow> -> Alt + Shift + <Arrow>
for arrow in arrows {
    shortcuts.append(
        KeyboardShortcutDefinition(
            fromKey: KeyboardCommand(keyPressed: true, keyCode: Int64(arrow), pressedKeys:[Int64(KeyCode.Control), Int64(KeyCode.Shift)]),
            toKey: KeyboardCommand(keyPressed: true, keyCode: Int64(arrow), pressedKeys:[Int64(KeyCode.Alt), Int64(KeyCode.Shift)]),
            applications: []
    ))
}

// Control + <Arrow> -> Alt + <Arrow>
for arrow in arrows {
    shortcuts.append(
        KeyboardShortcutDefinition(
            fromKey: KeyboardCommand(keyPressed: true, keyCode: Int64(arrow), pressedKeys:[Int64(KeyCode.Control)]),
            toKey: KeyboardCommand(keyPressed: true, keyCode: Int64(arrow), pressedKeys:[Int64(KeyCode.Alt)]),
            applications: []
    ))
}

func getActiveApplicationName() -> String {
    let ws = NSWorkspace.shared
    let apps = ws.runningApplications
    for currentApp in apps {
        if currentApp.activationPolicy != .regular {
            continue
        }
        
        if !currentApp.ownsMenuBar {
            continue
        }
        
        return currentApp.localizedName!
    }
    
    return ""
}

let EventSourceUserData = Int64(82411444529)

func getFlagsSet(event: CGEvent) -> [String] {
    var flags = [String]()
    
    if event.flags.rawValue & CGEventFlags.maskShift.rawValue != 0 {
        flags.append("Shift")
    }
    
    if event.flags.rawValue & CGEventFlags.maskCommand.rawValue != 0 {
        flags.append("Windows")
    }
    
    if event.flags.rawValue & CGEventFlags.maskControl.rawValue != 0 {
        flags.append("Control")
    }
    
    if event.flags.rawValue & CGEventFlags.maskAlternate.rawValue != 0 {
        flags.append("Alt")
    }
    
    if event.flags.rawValue & CGEventFlags.maskHelp.rawValue != 0 {
        flags.append("Help")
    }
    
    if event.flags.rawValue & CGEventFlags.maskAlphaShift.rawValue != 0 {
        flags.append("AlphaShift")
    }
    
    if event.flags.rawValue & CGEventFlags.maskNumericPad.rawValue != 0 {
        flags.append("NumericPad")
    }
    
    if event.flags.rawValue & CGEventFlags.maskNonCoalesced.rawValue != 0 {
        flags.append("NonCoalesced")
    }
    
    if event.flags.rawValue & CGEventFlags.maskSecondaryFn.rawValue != 0 {
        flags.append("SecondaryFn")
    }
    
    return flags
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    var ret = Unmanaged.passRetained(event) as Unmanaged<CGEvent>?
    
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let eventSourceUserData = event.getIntegerValueField(.eventSourceUserData)
    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat)
    
    
    
    
    if type == .keyDown {
        let spacing = EventSourceUserData == eventSourceUserData ? "\t->" : ""
        print("\(spacing)keyCode:\(keyCode) pressed:\(type == .keyDown) flags:\(getFlagsSet(event: event)) isRepeat:\(isRepeat)")
    }
    
    
    if EventSourceUserData == eventSourceUserData && isRepeat == 0 {
        return ret
    }
    
    // Needed for repeat keys where the primary key has already been pressed.
    var cleanedPressedKeys = Set<Int64>(pressedKeys)
    cleanedPressedKeys.remove(keyCode)
    
    
    for shortcut in shortcuts {
        if (type == .keyDown) != shortcut.fromKey.keyPressed {
            continue
        }
        
        if keyCode != shortcut.fromKey.keyCode {
            continue
        }
        
        if cleanedPressedKeys != shortcut.fromKey.pressedKeys {
            continue
        }
        
        if !shortcut.applications.isEmpty {
            if !shortcut.applications.contains(getActiveApplicationName()) {
                continue
            }
        }
        
        let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        src?.userData = EventSourceUserData
        let cmdd = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(shortcut.toKey.keyCode), keyDown: shortcut.toKey.keyPressed)
        cmdd?.flags = shortcut.toKey.getFlagsFromPressedKeys()
        cmdd?.post(tap: CGEventTapLocation.cghidEventTap)
        ret = nil
        
        break
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
