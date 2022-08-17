//
//  MIDIInputConnection.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if !os(tvOS) && !os(watchOS)

import Foundation
@_implementationOnly import CoreMIDI

/// A managed MIDI input connection created in the system by the MIDI I/O `MIDIManager`.
/// This connects to one or more outputs in the system and subscribes to receive their MIDI events.
///
/// - Note: Do not store or cache this object unless it is unavoidable. Instead, whenever possible call it by accessing the `MIDIManager`'s `managedInputConnections` collection.
///
/// Ensure that it is only stored weakly and only passed by reference temporarily in order to execute an operation. If it absolutely must be stored strongly, ensure it is stored for no longer than the lifecycle of the managed input connection (which is either at such time the `MIDIManager` is de-initialized, or when calling `.remove(.inputConnection, ...)` or `.removeAll` on the `MIDIManager` to destroy the managed input connection.)
public final class MIDIInputConnection: _MIDIIOManagedProtocol {
    // _MIDIIOManagedProtocol
    internal weak var midiManager: MIDIManager?
    
    // MIDIIOManagedProtocol
    public private(set) var api: CoreMIDIAPIVersion
    public var midiProtocol: MIDIProtocolVersion { api.midiProtocol }
    
    // class-specific
    
    public private(set) var outputsCriteria: Set<MIDIEndpointIdentity> = []
    
    /// Stores criteria after applying any filters that have been set in the `filter` property.
    /// Passing nil will re-use existing criteria, re-applying the filters.
    private func updateCriteria(_ criteria: Set<MIDIEndpointIdentity>? = nil) {
        var newCriteria = criteria ?? outputsCriteria
    
        if filter.owned,
           let midiManager = midiManager
        {
            let managedOutputs: [MIDIEndpointIdentity] = midiManager.managedOutputs
                .compactMap { $0.value.uniqueID }
                .map { .uniqueID($0) }
    
            newCriteria = newCriteria
                .filter { !managedOutputs.contains($0) }
        }
    
        if !filter.criteria.isEmpty {
            newCriteria = newCriteria
                .filter { !filter.criteria.contains($0) }
        }
    
        outputsCriteria = newCriteria
    }
    
    /// The Core MIDI input port reference.
    public private(set) var coreMIDIInputPortRef: CoreMIDIPortRef?
    
    /// The Core MIDI output endpoint(s) reference(s).
    public private(set) var coreMIDIOutputEndpointRefs: Set<CoreMIDIEndpointRef> = []
    
    /// Operating mode.
    ///
    /// Changes take effect immediately.
    public var mode: MIDIConnectionMode {
        didSet {
            guard oldValue != mode else { return }
            guard let midiManager = midiManager else { return }
            updateCriteriaFromMode()
            try? refreshConnection(in: midiManager)
        }
    }
    
    /// Reads the `mode` property and applies it to the stored criteria.
    private func updateCriteriaFromMode() {
        switch mode {
        case .allEndpoints:
            updateCriteria(.currentOutputs())
    
        case .definedEndpoints:
            updateCriteria()
        }
    }
    
    /// Endpoint filter.
    ///
    /// Changes take effect immediately.
    public var filter: MIDIEndpointFilter {
        didSet {
            guard oldValue != filter else { return }
            guard let midiManager = midiManager else { return }
            updateCriteria()
            try? refreshConnection(in: midiManager)
        }
    }
    
    /// Receive handler for inbound MIDI events.
    internal var receiveHandler: MIDIReceiveHandler
    
    // init
    
    /// Internal init.
    /// This object is not meant to be instanced by the user. This object is automatically created and managed by the MIDI I/O `MIDIManager` instance when calling `.addInputConnection()`, and destroyed when calling `.remove(.inputConnection, ...)` or `.removeAll()`.
    ///
    /// - Parameters:
    ///   - criteria: Output(s) to connect to.
    ///   - mode: Operation mode. Note that `allEndpoints` mode overrides `criteria`.
    ///   - filter: Optional filter allowing or disallowing certain endpoints from being added to the connection.
    ///   - receiver: Receive handler to use for incoming MIDI messages.
    ///   - midiManager: Reference to parent `MIDIManager` object.
    ///   - api: Core MIDI API version.
    internal init(
        criteria: Set<MIDIEndpointIdentity>,
        mode: MIDIConnectionMode,
        filter: MIDIEndpointFilter,
        receiver: MIDIReceiver,
        midiManager: MIDIManager,
        api: CoreMIDIAPIVersion = .bestForPlatform()
    ) {
        self.midiManager = midiManager
        self.mode = mode
        self.filter = filter
        self.receiveHandler = receiver.createReceiveHandler()
        self.api = api.isValidOnCurrentPlatform ? api : .bestForPlatform()
    
        // relies on midiManager, mode, and filter being set first
        if mode == .allEndpoints {
            updateCriteriaFromMode()
        } else {
            updateCriteria(criteria)
        }
    }
    
    deinit {
        try? disconnect()
        try? stopListening()
    }
}

extension MIDIInputConnection {
    /// Sets a new receiver.
    public func setReceiver(_ receiver: MIDIReceiver) {
        self.receiveHandler = receiver.createReceiveHandler()
    }
}

extension MIDIInputConnection {
    /// Returns the output endpoint(s) this connection is connected to.
    public var endpoints: [MIDIOutputEndpoint] {
        coreMIDIOutputEndpointRefs.map { MIDIOutputEndpoint(from: $0) }
    }
}

extension MIDIInputConnection {
    /// Create a MIDI Input port with which to subsequently connect to MIDI Output(s).
    ///
    /// - Parameter manager: MIDI manager instance by reference
    ///
    /// - Throws: `MIDIIOError`
    internal func listen(in manager: MIDIManager) throws {
        guard coreMIDIInputPortRef == nil else {
            // if we're already listening, it's not really an error condition
            // so just return; don't throw an error
            return
        }
    
        var newInputPortRef = MIDIPortRef()
    
        // connection name must be unique, otherwise process might hang (?)
    
        switch api {
        case .legacyCoreMIDI:
            // MIDIInputPortCreateWithBlock is deprecated after macOS 11 / iOS 14
            try MIDIInputPortCreateWithBlock(
                manager.coreMIDIClientRef,
                UUID().uuidString as CFString,
                &newInputPortRef,
                { [weak self] packetListPtr, srcConnRefCon in
                    guard let strongSelf = self else { return }
    
                    let packets = packetListPtr.packets()
    
                    strongSelf.midiManager?.eventQueue.async {
                        strongSelf.receiveHandler.packetListReceived(packets)
                    }
                }
            )
            .throwIfOSStatusErr()
    
        case .newCoreMIDI:
            guard #available(macOS 11, iOS 14, macCatalyst 14, *) else {
                throw MIDIIOError.internalInconsistency(
                    "New Core MIDI API is not accessible on this platform."
                )
            }
    
            try MIDIInputPortCreateWithProtocol(
                manager.coreMIDIClientRef,
                UUID().uuidString as CFString,
                api.midiProtocol.coreMIDIProtocol,
                &newInputPortRef,
                { [weak self] eventListPtr, srcConnRefCon in
                    guard let strongSelf = self else { return }
    
                    let packets = eventListPtr.packets()
                    let midiProtocol = MIDIProtocolVersion(eventListPtr.pointee.protocol)
    
                    strongSelf.midiManager?.eventQueue.async {
                        strongSelf.receiveHandler.eventListReceived(
                            packets,
                            protocol: midiProtocol
                        )
                    }
                }
            )
            .throwIfOSStatusErr()
        }
    
        coreMIDIInputPortRef = newInputPortRef
    }
    
    /// Disposes of the listening port if it exists.
    internal func stopListening() throws {
        guard let unwrappedInputPortRef = coreMIDIInputPortRef else { return }
    
        defer { self.coreMIDIInputPortRef = nil }
    
        try MIDIPortDispose(unwrappedInputPortRef)
            .throwIfOSStatusErr()
    }
    
    /// Connect to MIDI Output(s).
    ///
    /// - Parameters:
    ///   - manager: MIDI manager instance by reference
    ///   - disconnectStale: Disconnects stale connections that no longer match criteria.
    ///
    /// - Throws: `MIDIIOError`
    internal func connect(
        in manager: MIDIManager
    ) throws {
        // if not already listening, start listening
        if coreMIDIInputPortRef == nil {
            try listen(in: manager)
        }
    
        guard let unwrappedInputPortRef = coreMIDIInputPortRef else {
            throw MIDIIOError.connectionError(
                "Not in a listening state; can't connect to endpoints."
            )
        }
    
        // if previously connected, clean the old connections. ignore errors.
        try? disconnect()
    
        // resolve criteria to endpoints in the system
        let getOutputEndpointRefs = outputsCriteria
            .compactMap {
                $0.locate(in: manager.endpoints.outputs)?
                    .coreMIDIObjectRef
            }
    
        coreMIDIOutputEndpointRefs = Set(getOutputEndpointRefs)
    
        for outputEndpointRef in getOutputEndpointRefs {
            try? MIDIPortConnectSource(
                unwrappedInputPortRef,
                outputEndpointRef,
                nil
            )
            .throwIfOSStatusErr()
        }
    }
    
    /// Disconnects connections if any are currently connected.
    /// If nil is passed, the all of the connection's endpoint refs will be disconnected.
    ///
    /// Errors thrown can be safely ignored and are typically only useful for debugging purposes.
    internal func disconnect(
        endpointRefs: Set<MIDIEndpointRef>? = nil
    ) throws {
        guard let unwrappedInputPortRef = coreMIDIInputPortRef else {
            throw MIDIIOError.connectionError(
                "Attempted to disconnect outputs but was not in a listening state; nothing to disconnect."
            )
        }
    
        let refs = endpointRefs ?? coreMIDIOutputEndpointRefs
    
        for outputEndpointRef in refs {
            do {
                try MIDIPortDisconnectSource(
                    unwrappedInputPortRef,
                    outputEndpointRef
                )
                .throwIfOSStatusErr()
            } catch {
                // ignore errors
            }
        }
    }
    
    /// Refresh the connection.
    /// This is typically called after receiving a Core MIDI notification that system port configuration has changed or endpoints were added/removed.
    internal func refreshConnection(in manager: MIDIManager) throws {
        // call (re-)connect only if at least one matching endpoint exists in the system
    
        let getSystemOutputs = manager.endpoints.outputs
    
        var matchedEndpointCount = 0
    
        for criteria in outputsCriteria {
            if criteria.locate(in: getSystemOutputs) != nil { matchedEndpointCount += 1 }
        }
    
        try connect(in: manager)
    }
}

extension MIDIInputConnection {
    // MARK: Add Endpoints
    
    /// Add output endpoints to the connection.
    /// Endpoint filters are respected.
    public func add(
        outputs: [MIDIEndpointIdentity]
    ) {
        let combined = outputsCriteria.union(outputs)
        updateCriteria(combined)
    
        if let midiManager = midiManager {
            // this will re-generate coreMIDIOutputEndpointRefs and call connect()
            try? refreshConnection(in: midiManager)
        }
    }
    
    /// Add output endpoints to the connection.
    /// Endpoint filters are respected.
    @_disfavoredOverload
    public func add(
        outputs: [MIDIOutputEndpoint]
    ) {
        add(outputs: outputs.asIdentities())
    }
    
    // MARK: Remove Endpoints
    
    /// Remove output endpoints to the connection.
    public func remove(
        outputs: [MIDIEndpointIdentity]
    ) {
        let removed = outputsCriteria.subtracting(outputs)
        updateCriteria(removed)
    
        if let midiManager = midiManager {
            let refs = outputs
                .compactMap {
                    $0.locate(in: midiManager.endpoints.outputs)?
                        .coreMIDIObjectRef
                }
    
            // disconnect removed endpoints first
            try? disconnect(endpointRefs: Set(refs))
    
            // this will regenerate cached refs
            try? refreshConnection(in: midiManager)
        }
    }
    
    /// Remove output endpoints to the connection.
    @_disfavoredOverload
    public func remove(
        outputs: [MIDIOutputEndpoint]
    ) {
        remove(outputs: outputs.asIdentities())
    }
    
    public func removeAllOutputs() {
        let outputsToDisconnect = outputsCriteria
        updateCriteria([])
        remove(outputs: Array(outputsToDisconnect))
    }
}

extension MIDIInputConnection {
    internal func notification(_ internalNotification: MIDIIOInternalNotification) {
        if mode == .allEndpoints,
           let notif = MIDIIONotification(internalNotification, cache: nil),
           case .added(
               parent: _,
               child: let child
           ) = notif,
           case let .outputEndpoint(newOutput) = child
        {
            add(outputs: [newOutput])
            return
        }
    
        switch internalNotification {
        case .setupChanged, .added, .removed:
            if let midiManager = midiManager {
                try? refreshConnection(in: midiManager)
            }
    
        default:
            break
        }
    }
}

extension MIDIInputConnection: CustomStringConvertible {
    public var description: String {
        let outputEndpointsString: [String] = coreMIDIOutputEndpointRefs.map {
            // ref
            var str = "\($0):"
    
            // name
            if let getName = try? getName(of: $0) {
                str += "\(getName)".quoted
            } else {
                str += "nil"
            }
    
            return str
        }
    
        var inputPortRefString = "nil"
        if let unwrappedInputPortRef = coreMIDIInputPortRef {
            inputPortRefString = "\(unwrappedInputPortRef)"
        }
    
        return "MIDIInputConnection(criteria: \(outputsCriteria), outputEndpointRefs: \(outputEndpointsString), inputPortRef: \(inputPortRefString))"
    }
}

extension MIDIInputConnection: MIDIIOReceivesMIDIMessagesProtocol {
    // empty
}

#endif