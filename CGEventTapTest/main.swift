import Foundation
import Cocoa

struct KeyboardCommand : Decodable {
    // Set this to true to trigger the shortcut when the key is pressed. It should be set to false
    // when the shortcut should be triggered on release.
    var keyPressed: Bool
    var keyCode: KeyCode
    var pressedKeys: Set<KeyCode>
    
    init(keyPressed: Bool, keyCode: KeyCode, pressedKeys: Set<KeyCode>) {
        self.keyPressed = keyPressed
        self.keyCode = keyCode
        self.pressedKeys = pressedKeys
    }
    
    enum CodingKeys: String, CodingKey {
        case keyPressed, keyCode, pressedKeys
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let keyPressed = try container.decodeIfPresent(Bool.self, forKey: .keyPressed) {
            self.keyPressed = keyPressed
        } else {
            self.keyPressed = true
        }
        
        self.keyCode = try container.decode(KeyCode.self, forKey: .keyCode)
        
        if let pressedKeys = try container.decodeIfPresent(Set<KeyCode>.self, forKey: .pressedKeys) {
            self.pressedKeys = pressedKeys
        } else {
            self.pressedKeys = []
        }
    }
    
    func getFlagsFromPressedKeys() -> CGEventFlags {
        
        
        var result = UInt64(0)
        
        if self.pressedKeys.contains(KeyCode.Shift) {
            result |= CGEventFlags.maskShift.rawValue
        }
        
        if self.pressedKeys.contains(KeyCode.Control) {
            result |= CGEventFlags.maskControl.rawValue
        }
        
        if self.pressedKeys.contains(KeyCode.Windows) {
            result |= CGEventFlags.maskCommand.rawValue
        }
        
        if self.pressedKeys.contains(KeyCode.Alt) {
            result |= CGEventFlags.maskAlternate.rawValue
        }
        
        result |= CGEventFlags.maskNonCoalesced.rawValue
        
        return CGEventFlags(rawValue: result)
    }
}

struct KeyboardShortcutDefinition : Decodable {
    var fromKey: KeyboardCommand
    var toKey: KeyboardCommand
    var applications: Set<String>
    var name: String?
    
    init(fromKey: KeyboardCommand, toKey: KeyboardCommand, applications: Set<String>, name: String? = nil) {
        self.fromKey = fromKey
        self.toKey = toKey
        self.applications = applications
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case fromKey, toKey, applications, name, value
    }
    
    static func createKeyboardCommand(value: String) -> KeyboardCommand {
        let split = value.components(separatedBy: "+")
        
        var pressedKeys = Set<KeyCode>()
        for pressedKey in split.dropLast() {
            pressedKeys.insert(KeyCode.createFrom(rawValue: pressedKey))
        }
        
        return KeyboardCommand(keyPressed: true,
                               keyCode: KeyCode.createFrom(rawValue: split.last!),
                               pressedKeys: pressedKeys)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .value) {
            let valueSplit = value.components(separatedBy: "->")
            self.fromKey = KeyboardShortcutDefinition.createKeyboardCommand(value: valueSplit[0])
            self.toKey = KeyboardShortcutDefinition.createKeyboardCommand(value: valueSplit[1])
            
        } else {
            self.fromKey = try container.decode(KeyboardCommand.self, forKey: .fromKey)
            self.toKey = try container.decode(KeyboardCommand.self, forKey: .toKey)
        }
        
        if let applications = try container.decodeIfPresent(Set<String>.self, forKey: .applications) {
            self.applications = applications
        } else {
            self.applications = []
        }
        
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        } else {
            self.name = nil
        }
    }
}

struct KeyboardConfigurationGroup : Decodable {
    let shortcuts: [KeyboardShortcutDefinition]
    let name: String
}

struct KeyboardConfiguration : Decodable {
    let groups: [KeyboardConfigurationGroup]
}

var pressedKeys: Set<KeyCode> = []

var shortcuts: [KeyboardShortcutDefinition] = []

func getApplicationsNames() -> [String] {
    var result: [String] = []
    let ws = NSWorkspace.shared
    let apps = ws.runningApplications
    for currentApp in apps {
        if currentApp.activationPolicy != .regular {
            continue
        }
        
        result.append(currentApp.localizedName ?? "Unknown")
    }
    
    return result
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
    
    if event.flags.rawValue & CGEventFlags.maskAlternate.rawValue != 0 {
        flags.append("Windows")
    }
    
    if event.flags.rawValue & CGEventFlags.maskControl.rawValue != 0 {
        flags.append("Control")
    }
    
    if event.flags.rawValue & CGEventFlags.maskCommand.rawValue != 0 {
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

func swapModifierKeys(event: CGEvent) {
    var newFlags = event.flags
    
    if event.flags.rawValue & CGEventFlags.maskAlternate.rawValue != 0 {
        newFlags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | newFlags.rawValue)
    } else {
        newFlags = CGEventFlags(rawValue: ~CGEventFlags.maskCommand.rawValue & newFlags.rawValue)
    }
    
    if event.flags.rawValue & CGEventFlags.maskCommand.rawValue != 0 {
        newFlags = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | newFlags.rawValue)
    } else {
        newFlags = CGEventFlags(rawValue: ~CGEventFlags.maskAlternate.rawValue & newFlags.rawValue)
    }
    
    event.flags = newFlags
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    var ret = Unmanaged.passRetained(event) as Unmanaged<CGEvent>?
    
    let keyCodeOptional = KeyCode(rawValue: event.getIntegerValueField(.keyboardEventKeycode))
    let eventSourceUserData = event.getIntegerValueField(.eventSourceUserData)
    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat)
    
    
    if EventSourceUserData == eventSourceUserData && isRepeat == 0 {
        print("Out: keyDown:\(type == .keyDown) keyCode:\(keyCodeOptional ?? KeyCode.Unknown) pressed:\(type == .keyDown) flags:\(getFlagsSet(event: event))")
        return ret
    }
    
    if keyCodeOptional == nil {
        print("unknown key:\(event.getIntegerValueField(.keyboardEventKeycode))")
        print("")
        return ret
    }
    
    let keyCode = keyCodeOptional!
    
    let spacing = EventSourceUserData == eventSourceUserData ? "\t->" : ""
    if isRepeat == 0 {
        print("\(spacing)keyDown:\(type == .keyDown) keyCode:\(keyCodeOptional ?? KeyCode.Unknown) pressed:\(type == .keyDown) flags:\(getFlagsSet(event: event))")
    }
    
    
    
    
    
    // Needed for repeat keys where the primary key has already been pressed.
    var cleanedPressedKeys = Set<KeyCode>(pressedKeys)
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
        let cmdd = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(shortcut.toKey.keyCode.rawValue), keyDown: shortcut.toKey.keyPressed)
        cmdd?.flags = shortcut.toKey.getFlagsFromPressedKeys()
        cmdd?.post(tap: CGEventTapLocation.cghidEventTap)
        ret = nil
        
        print("name:\(shortcut.name ?? "")")
        
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
            pressedKeys.insert(KeyCode.Shift)
        } else {
            pressedKeys.remove(KeyCode.Shift)
        }
        
        if event.flags.rawValue & CGEventFlags.maskControl.rawValue != 0 {
            pressedKeys.insert(KeyCode.Control)
        } else {
            pressedKeys.remove(KeyCode.Control)
        }
        
        if event.flags.rawValue & CGEventFlags.maskCommand.rawValue != 0 {
            pressedKeys.insert(KeyCode.Alt)
        } else {
            pressedKeys.remove(KeyCode.Alt)
        }
        
        if event.flags.rawValue & CGEventFlags.maskAlternate.rawValue != 0 {
            pressedKeys.insert(KeyCode.Windows)
        } else {
            pressedKeys.remove(KeyCode.Windows)
        }
    }
    
    print("pressedKeys:\(pressedKeys)")
    if ret != nil {
        print("")
    }
    return ret
}

func loadHotKeysFromFile(fileName: String) throws -> KeyboardConfiguration? {
    

    // Set the file path
    let path = fileName


    // Get the contents
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    print(contents)
    
    
    let jsonData = contents.data(using: .utf8)!

    let decodeResult = try JSONDecoder().decode(KeyboardConfiguration.self, from: jsonData)
    
    return decodeResult

}

func loadHotKeyMaps() {
    print("applicationNames:\(getApplicationsNames().joined(separator: ","))")
    var newShortcuts: [KeyboardShortcutDefinition] = [
        KeyboardShortcutDefinition(
            fromKey: KeyboardCommand(keyPressed: true, keyCode: KeyCode.X, pressedKeys:[KeyCode.Control]),
            toKey: KeyboardCommand(keyPressed: true, keyCode: KeyCode.C, pressedKeys:[KeyCode.Control]),
            applications: ["Terminal"]
        )
    ]

    // Control + Shift + <Arrow> -> Alt + Shift + <Arrow>
    for arrow in arrows {
        newShortcuts.append(
            KeyboardShortcutDefinition(
                fromKey: KeyboardCommand(keyPressed: true, keyCode: arrow, pressedKeys:[KeyCode.Control, KeyCode.Shift]),
                toKey: KeyboardCommand(keyPressed: true, keyCode: arrow, pressedKeys:[KeyCode.Alt, KeyCode.Shift]),
                applications: []
        ))
    }

    // Control + <Arrow> -> Alt + <Arrow>
    for arrow in arrows {
        newShortcuts.append(
            KeyboardShortcutDefinition(
                fromKey: KeyboardCommand(keyPressed: true, keyCode: arrow, pressedKeys:[KeyCode.Control]),
                toKey: KeyboardCommand(keyPressed: true, keyCode: arrow, pressedKeys:[KeyCode.Alt]),
                applications: []
        ))
    }
    
    do {
        
        // Get the directory contents urls (including subfolders urls)
        let directoryContents = try FileManager.default.contentsOfDirectory(
            atPath: "."
        )
        
        print("directoryContents:\(directoryContents)")
        
        for file in directoryContents {
            if !file.hasSuffix(".keyconfig.json") {
                continue
            }
            
            print("reading key config file: \(file)")
            
            let fileConfig = try loadHotKeysFromFile(fileName: file)
            
            if fileConfig == nil {
                print("null file config")
                continue
            }
            
            
            
            var addedCount = 0
            for group in fileConfig!.groups {
                for shortcut in group.shortcuts {
                    newShortcuts.append(shortcut)
                    print(shortcut)
                    addedCount += 1
                }
            }
            
            
            print("added \(addedCount) shortcuts from file \(file)")
        }
    } catch {
        print("Error in loadHotKeyMaps:\(error)")
    }
    
    
    
    // Control + <Letter> -> WindowsKey + <Letter>
    for letter in letters {
        newShortcuts.append(
            KeyboardShortcutDefinition(
                fromKey: KeyboardCommand(keyPressed: true, keyCode: letter, pressedKeys:[KeyCode.Control]),
                toKey: KeyboardCommand(keyPressed: true, keyCode: letter, pressedKeys:[KeyCode.Windows]),
                applications: []
        ))
    }
    
    shortcuts = newShortcuts
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

loadHotKeyMaps()

class FileSystemObjectObserver {
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol
    private let path: String

    init(path: String, handler: (()->Void)?) {
        self.fileDescriptor = open(path, O_EVTONLY)
        self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor, eventMask: .all, queue: DispatchQueue.global())
        self.source.setEventHandler {
            print("FILE CHANGED:\(path)")
            if handler != nil {
                handler!()
            }
        }
        self.source.resume()
        self.path = path
    }
    
    func setHandler(handler: (()->Void)?) {
        self.source.setEventHandler {
            print("FILE CHANGED:\(self.path)")
            if handler != nil {
                handler!()
            }
        }
    }
    
    deinit {
        self.source.cancel()
        close(fileDescriptor)
    }
}

class DirectoryContentsObserver {
    private var files = [String: FileSystemObjectObserver]()
    private let directory: FileSystemObjectObserver
    private let handler: () -> Void

    init(path: String, handler: @escaping ()->Void) {
        self.handler = handler
        self.directory = FileSystemObjectObserver(path: path, handler: nil)
        self.directory.setHandler(handler: self.directoryChangedHandler)
        directoryChangedHandler()
    }
    
    private func directoryChangedHandler() {
        print("DIRCTORY CHANGED")
        do {
            let currentFiles = Set<String>(try FileManager.default.contentsOfDirectory(atPath: "."))
            print("currentFiles:\(currentFiles)")
            
            // Remove files that are no longer there.
            for file in self.files {
                if !currentFiles.contains(file.key) {
                    print("REMOVING WATCHED FILE:\(file.key)")
                    self.files.removeValue(forKey: file.key)
                }
            }
            
            // Add the ones that are.
            for file in currentFiles {
                if self.files[file] != nil {
                    continue
                }
                
                if !file.hasSuffix(".keyconfig.json") {
                    continue
                }
                
                print("WATCHING NEW FILE:\(file)")
                let observer = FileSystemObjectObserver(path: file, handler: {
                    self.handler()
                })
                self.files.updateValue(observer, forKey: file)
            }
        } catch {
            print("Error in directory change event:\(error)")
        }
        
        self.handler()
    }
}

var observer = DirectoryContentsObserver(path: ".", handler: loadHotKeyMaps)


let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)
CFRunLoopRun()

