//
//  MIDIIOSendsMIDIMessagesProtocol.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//

#if !os(tvOS) && !os(watchOS)

@_implementationOnly import CoreMIDI

// MARK: - Public Protocol

public protocol MIDIIOSendsMIDIMessagesProtocol: MIDIIOManagedProtocol {
    
    /// The Core MIDI output port ref.
    /* public private(set) */ var coreMIDIOutputPortRef: MIDI.IO.PortRef? { get }
    
    /// MIDI Protocol version used for this endpoint.
    /* public private(set) */ var midiProtocol: MIDI.IO.ProtocolVersion { get }
    
    /// Send a MIDI Event.
    func send(event: MIDI.Event) throws
    
    /// Send one or more MIDI Events.
    func send(events: [MIDI.Event]) throws
    
}

// MARK: - Internal Protocol

internal protocol _MIDIIOSendsMIDIMessagesProtocol: MIDIIOSendsMIDIMessagesProtocol {
    
    /// Internal:
    /// Send a MIDI Message, automatically assembling it into a `MIDIPacketList`.
    ///
    /// - Parameter rawMessage: MIDI message
    func send(rawMessage: [MIDI.Byte]) throws
    
    /// Internal:
    /// Send one or more MIDI message(s), automatically assembling it into a `MIDIPacketList`.
    ///
    /// - Parameter rawMessages: Array of MIDI messages
    func send(rawMessages: [[MIDI.Byte]]) throws
    
    /// Internal:
    /// Send a Core MIDI `MIDIPacketList`. (MIDI 1.0, using old Core MIDI API).
    func send(packetList: UnsafeMutablePointer<MIDIPacketList>) throws
    
    /// Internal:
    /// Send a Core MIDI `MIDIEventList`. (MIDI 1.0 and 2.0, using new Core MIDI API).
    @available(macOS 11, iOS 14, macCatalyst 14, *)
    func send(eventList: UnsafeMutablePointer<MIDIEventList>) throws
    
    /// Internal:
    /// Send a MIDI message inside a Universal MIDI Packet.
    ///
    /// - Parameter rawWords: Array of `UInt32` words
    @available(macOS 11, iOS 14, macCatalyst 14, *)
    func send(rawWords: [MIDI.UMPWord]) throws
    
}

// MARK: - Implementation

extension _MIDIIOSendsMIDIMessagesProtocol {
    
    @inline(__always)
    internal func send(rawMessage: [MIDI.Byte]) throws {
        
        switch api {
        case .legacyCoreMIDI:
            var packetList = MIDIPacketList(data: rawMessage)
            
            try withUnsafeMutablePointer(to: &packetList) { ptr in
                try send(packetList: ptr)
            }
            
        case .newCoreMIDI:
            throw MIDI.IO.MIDIError.internalInconsistency("Raw bytes cannot be sent using new Core MIDI API.")
            
        }
        
    }
    
    @inline(__always)
    internal func send(rawMessages: [[MIDI.Byte]]) throws {
        
        switch api {
        case .legacyCoreMIDI:
            var packetList = try MIDIPacketList(data: rawMessages)
            
            try withUnsafeMutablePointer(to: &packetList) { ptr in
                try send(packetList: ptr)
            }
            
        case .newCoreMIDI:
            throw MIDI.IO.MIDIError.internalInconsistency("Raw bytes cannot be sent using new Core MIDI API.")
            
        }
        
    }
    
    @available(macOS 11, iOS 14, macCatalyst 14, *)
    @inline(__always)
    internal func send(rawWords: [MIDI.UMPWord]) throws {
        
        switch api {
        case .legacyCoreMIDI:
            throw MIDI.IO.MIDIError.internalInconsistency(
                "Universal MIDI Packet words cannot be sent using old Core MIDI API."
            )
            
        case .newCoreMIDI:
            var eventList = try MIDIEventList(
                protocol: self.midiProtocol.coreMIDIProtocol,
                packetWords: rawWords
            )
            
            try withUnsafeMutablePointer(to: &eventList) { ptr in
                try send(eventList: ptr)
            }
            
        }
        
    }
    
}

extension _MIDIIOSendsMIDIMessagesProtocol {
    
    @inline(__always)
    public func send(event: MIDI.Event) throws {
        
        switch api {
        case .legacyCoreMIDI:
            try send(rawMessage: event.midi1RawBytes())
            
        case .newCoreMIDI:
            guard #available(macOS 11, iOS 14, macCatalyst 14, *) else {
                throw MIDI.IO.MIDIError.internalInconsistency(
                    "New Core MIDI API is not accessible on this platform."
                )
            }
            
            for eventWords in event.umpRawWords(protocol: self.midiProtocol) {
                try send(rawWords: eventWords)
            }
            
        }
        
    }
    
    @inline(__always)
    public func send(events: [MIDI.Event]) throws {
        
        switch api {
        case .legacyCoreMIDI:
            if events.contains(where: { $0.isSystemExclusive }) {
                // System Exclusive events must be the only event in a MIDIPacketList
                // so force each event to be sent in its own packet
                try events.forEach { try send(event: $0) }
            } else {
                // combine events into a single MIDIPacketList
                try send(rawMessages: events.map { $0.midi1RawBytes() })
            }
            
        case .newCoreMIDI:
            guard #available(macOS 11, iOS 14, macCatalyst 14, *) else {
                throw MIDI.IO.MIDIError.internalInconsistency(
                    "New Core MIDI API is not accessible on this platform."
                )
            }
            
            for event in events {
                for eventWords in event.umpRawWords(protocol: self.midiProtocol) {
                    try send(rawWords: eventWords)
                }
            }
            
        }
        
    }
    
}

#endif
