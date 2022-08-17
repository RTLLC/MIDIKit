//
//  MIDIEvent Filter Group.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2022 Steffan Andrews • Licensed under MIT License
//

// MARK: - Filter

extension Collection where Element == MIDIEvent {
    /// Filter events by UMP group.
    @inlinable
    public func filter(group: UInt4) -> [Element] {
        filter { $0.group == group }
    }
    
    /// Filter events by UMP groups.
    @inlinable
    public func filter(groups: [UInt4]) -> [Element] {
        filter { groups.contains($0.group) }
    }
}

// MARK: - Drop

extension Collection where Element == MIDIEvent {
    /// Drop all events with the specified UMP group.
    @inlinable
    public func drop(group: UInt4) -> [Element] {
        filter { $0.group != group }
    }
    
    /// Drop all events with any of the specified UMP groups.
    @inlinable
    public func drop(groups: [UInt4]) -> [Element] {
        filter { !groups.contains($0.group) }
    }
}