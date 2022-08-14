//
//  MIDIIOObject.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if !os(tvOS) && !os(watchOS)

import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public protocol MIDIIOObject {
    /// Enum describing the abstracted object type.
    var objectType: MIDIIOObjectType { get }
    
    /// Name of the object.
    var name: String { get }
    
    /// The unique ID for the Core MIDI object.
    var uniqueID: MIDIIdentifier { get }
    
    /// The Core MIDI object reference.
    var coreMIDIObjectRef: CoreMIDIObjectRef { get }
    
    /// Return as `AnyMIDIIOObject`, a type-erased representation of a MIDIKit object conforming to `MIDIIOObject`.
    func asAnyMIDIIOObject() -> AnyMIDIIOObject
    
    // MARK: - MIDIIOObject Comparison.swift
    
    static func == (lhs: Self, rhs: Self) -> Bool
    func hash(into hasher: inout Hasher)
    
    // MARK: - MIDIIOObject Properties.swift
    
    // Identification
    func getName() -> String?
    func getModel() -> String?
    func getManufacturer() -> String?
    func getUniqueID() -> MIDIIdentifier
    func getDeviceManufacturerID() -> Int32
    
    // Capabilities
    func getSupportsMMC() -> Bool
    func getSupportsGeneralMIDI() -> Bool
    func getSupportsShowControl() -> Bool
    
    // Configuration
    @available(macOS 10.15, macCatalyst 13.0, iOS 13.0, *)
    func getNameConfigurationDictionary() -> NSDictionary?
    func getMaxSysExSpeed() -> Int32
    func getDriverDeviceEditorApp() -> URL?
    
    // Presentation
    func getImageFileURL() -> URL?
    #if canImport(AppKit) && os(macOS)
    func getImageAsNSImage() -> NSImage?
    #endif
    #if canImport(UIKit)
    func getImageAsUIImage() -> UIImage?
    #endif
    func getDisplayName() -> String?
    
    // Audio
    func getPanDisruptsStereo() -> Bool
    
    // Protocols
    @available(macOS 11.0, macCatalyst 14.0, iOS 14.0, *)
    func getProtocolID() -> MIDIProtocolVersion?
    
    // Timing
    func getTransmitsMTC() -> Bool
    func getReceivesMTC() -> Bool
    func getTransmitsClock() -> Bool
    func getReceivesClock() -> Bool
    func getAdvanceScheduleTimeMuSec() -> String?
    
    // Roles
    func getIsMixer() -> Bool
    func getIsSampler() -> Bool
    func getIsEffectUnit() -> Bool
    func getIsDrumMachine() -> Bool
    
    // Status
    func getIsOffline() -> Bool
    func getIsPrivate() -> Bool
    
    // Drivers
    func getDriverOwner() -> String?
    func getDriverVersion() -> Int32
    
    // Connections
    func getCanRoute() -> Bool
    func getIsBroadcast() -> Bool
    func getConnectionUniqueID() -> MIDIIdentifier
    func getIsEmbeddedEntity() -> Bool
    func getSingleRealtimeEntity() -> Int32
    
    // Channels
    func getReceiveChannels() -> Int32
    func getTransmitChannels() -> Int32
    func getMaxReceiveChannels() -> Int32
    func getMaxTransmitChannels() -> Int32
    
    // Banks
    func getReceivesBankSelectLSB() -> Bool
    func getReceivesBankSelectMSB() -> Bool
    func getTransmitsBankSelectLSB() -> Bool
    func getTransmitsBankSelectMSB() -> Bool
    
    // Notes
    func getReceivesNotes() -> Bool
    func getTransmitsNotes() -> Bool
    func getReceivesProgramChanges() -> Bool
    func getTransmitsProgramChanges() -> Bool
    
    // MARK: - MIDIIOObject Properties Dictionary.swift
    
    func getPropertiesAsStrings(
        onlyIncludeRelevant: Bool
    ) -> [(key: String, value: String)]
}

#endif