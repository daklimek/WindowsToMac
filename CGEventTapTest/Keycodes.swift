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

    case Q = 12
    case W = 13
    case E = 14
    case R = 15
    case T = 17
    case Y = 16
    case U = 32
    case I = 34
    case O = 31
    case P = 35
    
    case A = 0
    case S = 1
    case D = 2
    case F = 3
    case G = 5
    case H = 4
    case J = 38
    case K = 40
    case L = 37
    
    case Z = 6
    case X = 7
    case C = 8
    case V = 9
    case B = 11
    case N = 45
    case M = 46
    
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
    KeyCode.Q,
    KeyCode.W,
    KeyCode.E,
    KeyCode.R,
    KeyCode.T,
    KeyCode.Y,
    KeyCode.U,
    KeyCode.I,
    KeyCode.O,
    KeyCode.P,
    
    KeyCode.A,
    KeyCode.S,
    KeyCode.D,
    KeyCode.F,
    KeyCode.G,
    KeyCode.H,
    KeyCode.J,
    KeyCode.K,
    KeyCode.L,
    
    KeyCode.Z,
    KeyCode.X,
    KeyCode.C,
    KeyCode.V,
    KeyCode.B,
    KeyCode.N,
    KeyCode.M
]

let arrows:[KeyCode] = [
    KeyCode.LeftArrow,
    KeyCode.DownArrow,
    KeyCode.UpArrow,
    KeyCode.RightArrow
]
