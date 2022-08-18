//
//  UInt7.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import MIDIKitInternals

/// A 7-bit unsigned integer value type used in `MIDIKit`.
public struct UInt7: MIDIIntegerProtocol {
    // MARK: Storage
    
    public typealias Storage = UInt8
    public internal(set) var value: Storage
    
    // MARK: Inits
    
    public init() {
        value = 0
    }
    
    public init<T: BinaryInteger>(_ source: T) {
        if source < Self.min(Storage.self) {
            Exception.underflow.raise(reason: "UInt7 integer underflowed")
        }
        if source > Self.max(Storage.self) {
            Exception.overflow.raise(reason: "UInt7 integer overflowed")
        }
        value = Storage(source)
    }
    
    public init<T: BinaryFloatingPoint>(_ source: T) {
        // it should be safe to cast as T.self since it's virtually impossible
        // that we will encounter a BinaryFloatingPoint type that cannot fit UInt7.max
        if source < Self.min(T.self) {
            Exception.underflow.raise(reason: "UInt7 integer underflowed")
        }
        if source > Self.max(T.self) {
            Exception.overflow.raise(reason: "UInt7 integer overflowed")
        }
        value = Storage(source)
    }
    
    // MARK: Constants
    
    public static let bitWidth: Int = 7
    
    public static func min<T: BinaryInteger>(_ ofType: T.Type) -> T { 0 }
    public static func min<T: BinaryFloatingPoint>(_ ofType: T.Type) -> T { 0 }
    
    // 0b100_0000, int 64, hex 0x40
    public static let midpoint = Self(Self.midpoint(Storage.self))
    public static func midpoint<T: BinaryInteger>(_ ofType: T.Type) -> T { 0b1000000 }
    
    // 0b111_1111, int 127, hex 0x7F
    public static func max<T: BinaryInteger>(_ ofType: T.Type) -> T { 0b1111111 }
    public static func max<T: BinaryFloatingPoint>(_ ofType: T.Type) -> T { 0b1111111 }
    
    // MARK: Computed properties
    
    /// Returns the integer as a `UInt8` instance
    public var uInt8Value: UInt8 { value }
}

extension UInt7: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Storage
    
    public init(integerLiteral value: Storage) {
        self.init(value)
    }
}

extension UInt7: Strideable {
    public typealias Stride = Int
    
    public func advanced(by n: Stride) -> Self {
        self + Self(n)
    }
    
    public func distance(to other: Self) -> Stride {
        Stride(other) - Stride(self)
    }
}

extension UInt7: Equatable, Comparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension UInt7: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension UInt7: Codable {
    enum CodingKeys: String, CodingKey {
        case value = "UInt7"
    }
}

extension UInt7: CustomStringConvertible {
    public var description: String {
        "\(value)"
    }
}

// MARK: - Standard library extensions

extension BinaryInteger {
    /// Convenience initializer for `UInt7`.
    public var toUInt7: UInt7 {
        UInt7(self)
    }
    
    /// Convenience initializer for `UInt7(exactly:)`.
    public var toUInt7Exactly: UInt7? {
        UInt7(exactly: self)
    }
}

extension BinaryFloatingPoint {
    /// Convenience initializer for `UInt7`.
    public var toUInt7: UInt7 {
        UInt7(self)
    }
    
    /// Convenience initializer for `UInt7(exactly:)`.
    public var toUInt7Exactly: UInt7? {
        UInt7(exactly: self)
    }
}