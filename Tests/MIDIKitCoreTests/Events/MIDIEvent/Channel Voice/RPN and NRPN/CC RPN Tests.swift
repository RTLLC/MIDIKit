//
//  CC RPN Tests.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2023 Steffan Andrews • Licensed under MIT License
//

#if shouldTestCurrentPlatform

import XCTest
import MIDIKitCore

final class MIDIEvent_CC_RPN_Tests: XCTestCase {
    // swiftformat:options --wrapcollections preserve
    // swiftformat:disable spaceInsideParens spaceInsideBrackets
    
    // MARK: - midi1RPN()
    
    func testRPN_MIDI1_NoDataEntry() {
        let rpn: [MIDIEvent] = MIDIEvent.midi1RPN(
            .raw(
                parameter: .init(msb: 66, lsb: 103),
                dataEntryMSB: nil,
                dataEntryLSB: nil
            ),
            channel: 0x9
        )
    
        XCTAssertEqual(
            rpn.flatMap { $0.midi1RawBytes() },
            [0xB9, 0x65, 66,
             0xB9, 0x64, 103]
        )
    }
    
    func testRPN_MIDI1_DataEntryMSB() {
        let rpn: [MIDIEvent] = MIDIEvent.midi1RPN(
            .raw(
                parameter: .init(msb: 66, lsb: 103),
                dataEntryMSB: 127,
                dataEntryLSB: nil
            ),
            channel: 0x9
        )
    
        XCTAssertEqual(
            rpn.flatMap { $0.midi1RawBytes() },
            [0xB9, 0x65, 66,
             0xB9, 0x64, 103,
             0xB9, 0x06, 127]
        )
    }
    
    func testRPN_MIDI1_testRPN_MIDI1_DataEntryMSBandLSB() {
        let rpn: [MIDIEvent] = MIDIEvent.midi1RPN(
            .raw(
                parameter: .init(msb: 66, lsb: 103),
                dataEntryMSB: 127,
                dataEntryLSB: 2
            ),
            channel: 0x9
        )
    
        XCTAssertEqual(
            rpn.flatMap { $0.midi1RawBytes() },
            [0xB9, 0x65, 66,
             0xB9, 0x64, 103,
             0xB9, 0x06, 127,
             0xB9, 0x26, 2]
        )
    }
    
    func testRPN_MIDI1_Null() {
        let nrpn: [MIDIEvent] = MIDIEvent.midi1RPN(
            .null,
            channel: 0x9
        )
    
        XCTAssertEqual(
            nrpn.flatMap { $0.midi1RawBytes() },
            [0xB9, 0x65, 0x7F,
             0xB9, 0x64, 0x7F]
        )
    }
}

#endif