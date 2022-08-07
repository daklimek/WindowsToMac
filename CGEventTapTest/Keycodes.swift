enum KeyCode : Int64, Decodable, CaseIterable {
    case Control = 59
    case Windows = 61
    case Alt = 54
    case Shift = 56
    case CapsLock = 57
    case Tab = 48
    case Space = 49
    case Delete = 117
    case Backspace = 51
    case Tilda = 50
    
    case Num1 = 18
    case Num2 = 19
    case Num3 = 20
    case Num4 = 21
    case Num5 = 23
    case Num6 = 22
    case Num7 = 26
    case Num8 = 28
    case Num9 = 25
    case Num0 = 29

    case LetterQ = 12
    case LetterW = 13
    case LetterE = 14
    case LetterR = 15
    case LetterT = 17
    case LetterY = 16
    case LetterU = 32
    case LetterI = 34
    case LetterO = 31
    case LetterP = 35
    
    case LetterA = 0
    case LetterS = 1
    case LetterD = 2
    case LetterF = 3
    case LetterG = 5
    case LetterH = 4
    case LetterJ = 38
    case LetterK = 40
    case LetterL = 37
    
    case LetterZ = 6
    case LetterX = 7
    case LetterC = 8
    case LetterV = 9
    case LetterB = 11
    case LetterN = 45
    case LetterM = 46
    
    case LeftArrow = 123
    case DownArrow = 125
    case UpArrow = 126
    case RightArrow = 124
    
    
    case Unknown = -1
    
    static var map = [String: KeyCode]()
    static func initMap() {
        
        if !map.isEmpty {
            return
        }
        
        for keyCode in KeyCode.allCases {
            map.updateValue(keyCode, forKey: "\(keyCode)")
        }
    }
    
    static func createFrom(rawValue: String) -> KeyCode {
        initMap()
        return map[rawValue, default: KeyCode.Unknown]
    }
    
    
    init(from decoder: Decoder) throws {
        let label = try decoder.singleValueContainer().decode(String.self)
        
        self = KeyCode.createFrom(rawValue: label)
    }
}

let letters:[KeyCode] = [
    KeyCode.LetterQ,
    KeyCode.LetterW,
    KeyCode.LetterE,
    KeyCode.LetterR,
    KeyCode.LetterT,
    KeyCode.LetterY,
    KeyCode.LetterU,
    KeyCode.LetterI,
    KeyCode.LetterO,
    KeyCode.LetterP,
    
    KeyCode.LetterA,
    KeyCode.LetterS,
    KeyCode.LetterD,
    KeyCode.LetterF,
    KeyCode.LetterG,
    KeyCode.LetterH,
    KeyCode.LetterJ,
    KeyCode.LetterK,
    KeyCode.LetterL,
    
    KeyCode.LetterZ,
    KeyCode.LetterX,
    KeyCode.LetterC,
    KeyCode.LetterV,
    KeyCode.LetterB,
    KeyCode.LetterN,
    KeyCode.LetterM
]

let arrows:[KeyCode] = [
    KeyCode.LeftArrow,
    KeyCode.DownArrow,
    KeyCode.UpArrow,
    KeyCode.RightArrow
]
