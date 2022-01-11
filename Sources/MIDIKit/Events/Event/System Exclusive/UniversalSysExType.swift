//
//  UniversalSysExType.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//

extension MIDI.Event {
    
    /// Universal System Exclusive message type.
    public enum UniversalSysExType: MIDI.UInt7, Equatable, Hashable {
        
        /// Real Time System Exclusive ID number (`0x7F`).
        case realTime = 0x7F
        
        /// Non-Real Time System Exclusive ID number (`0x7E`).
        case nonRealTime = 0x7E
        
        public init?(rawValue: UInt8) {
            
            guard let uInt7 = MIDI.UInt7(exactly: rawValue) else { return nil }
            
            self.init(rawValue: uInt7)
            
        }
        
    }
    
}

extension MIDI.Event.UniversalSysExType: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .realTime: return "realTime"
        case .nonRealTime: return "nonRealTime"
        }
        
    }
    
}