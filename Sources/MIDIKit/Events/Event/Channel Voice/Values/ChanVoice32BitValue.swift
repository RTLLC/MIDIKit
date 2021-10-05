//
//  ChanVoice32BitValue.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//

extension MIDI.Event {
    
    /// Channel Voice 32-Bit (MIDI 2.0) Value
    public enum ChanVoice32BitValue: Hashable {
        
        /// Protocol-agnostic unit interval (0.0...1.0)
        /// Scaled automatically depending on MIDI protocol (1.0/2.0) in use.
        case unitInterval(Double)
        
        /// MIDI 2.0 32-bit Channel Voice Value (0x00000000...0xFFFFFFFF)
        case midi2(UInt32)
        
        // conversion initializers from MIDI 1 value types
        
        /// Returns `.unitInterval()` case converting from a MIDI 1.0 7-Bit value.
        public static func midi1(sevenBit: MIDI.UInt7) -> Self {
            
            let scaled = Double(sevenBit.uInt8Value) / 0x7F
            return .unitInterval(scaled)
            
        }
        
        /// Returns `.unitInterval()` case converting from a MIDI 1.0 14-Bit value.
        public static func midi1(fourteenBit: MIDI.UInt14) -> Self {
            
            let scaled = Double(fourteenBit.uInt16Value) / 0x3FFF
            return .unitInterval(scaled)
            
        }
        
    }
    
}

extension MIDI.Event.ChanVoice32BitValue: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        
        switch lhs {
        case .unitInterval(let lhsInterval):
            switch rhs {
            case .unitInterval(let rhsInterval):
                return lhsInterval == rhsInterval
                
            case .midi2(let rhsUInt32):
                return lhs.midi2Value == rhsUInt32
                
            }
            
        case .midi2(let lhsUInt32):
            switch rhs {
            case .unitInterval(let rhsInterval):
                return lhs.unitIntervalValue == rhsInterval
                
            case .midi2(let rhsUInt32):
                return lhsUInt32 == rhsUInt32
                
            }
            
        }
        
    }
    
}

extension MIDI.Event.ChanVoice32BitValue {
    
    /// Returns value as protocol-agnostic unit interval, converting if necessary.
    public var unitIntervalValue: Double {
        
        switch self {
        case .unitInterval(let interval):
            return interval.clamped(to: 0.0...1.0)
                        
        case .midi2(let uInt32):
            return Double(uInt32) / 0xFFFFFFFF
            
        }
        
    }
    
    /// Returns value as a MIDI 1.0 7-bit value, converting if necessary.
    public var midi1_7BitValue: MIDI.UInt7 {
        
        switch self {
        case .unitInterval(let interval):
            let scaled = interval.clamped(to: 0.0...1.0) * 0x7F
            return MIDI.UInt7(scaled.rounded())
            
        case .midi2(let uInt32):
            let scaled = (Double(uInt32) / 0xFFFFFFFF) * 0x7F
            return MIDI.UInt7(scaled.rounded())
            
        }
        
    }
    
    /// Returns value as a MIDI 1.0 14-bit value, converting if necessary.
    public var midi1_14BitValue: MIDI.UInt14 {
        
        switch self {
        case .unitInterval(let interval):
            let scaled = interval.clamped(to: 0.0...1.0) * 0x3FFF
            return MIDI.UInt14(scaled.rounded())
            
        case .midi2(let uInt32):
            let scaled = (Double(uInt32) / 0xFFFFFFFF) * 0x3FFF
            return MIDI.UInt14(scaled.rounded())
            
        }
        
    }
    
    /// Returns value as a MIDI 2.0 32-bit value, converting if necessary.
    public var midi2Value: UInt32 {
        
        switch self {
        case .unitInterval(let interval):
            let scaled = interval.clamped(to: 0.0...1.0) * 0xFFFFFFFF
            return UInt32(scaled.rounded())
            
        case .midi2(let uInt32):
            return uInt32
            
        }
        
    }
    
}

extension MIDI.Event.ChanVoice32BitValue {
    
    @propertyWrapper
    public struct Validated: Equatable, Hashable {
        
        public typealias Value = MIDI.Event.ChanVoice32BitValue
        
        private var value: Value
        
        public var wrappedValue: Value {
            get {
                value
            }
            set {
                switch newValue {
                case .unitInterval(let interval):
                    value = .unitInterval(interval.clamped(to: 0.0...1.0))
                    
                case .midi2:
                    value = newValue
                }
            }
        }
        
        public init(wrappedValue: Value) {
            self.value = wrappedValue
        }
        
    }
    
}
