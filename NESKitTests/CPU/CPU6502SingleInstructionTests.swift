//
//  CPU6502SingleInstructionTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPU6502SingleInstructionTests: XCTestCase {
    var subject: CPU6502!
    
    override func setUp() {
        super.setUp()
        subject = nil
    }

    func testLDAImmediate() {
        let memory = CPUMemory(ram: UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                                           alignment: 1),
                               mapper: DebugReadOnlyPRGMapper(Data([0xA9,0x50,0xA9,0xFF,0xA9,0x00])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(subject.accumulator, 0x50)
        XCTAssertFalse(subject.zero)
        XCTAssertFalse(subject.negative)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(subject.accumulator, 0xFF)
        XCTAssertFalse(subject.zero)
        XCTAssertTrue(subject.negative)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(subject.accumulator, 0x00)
        XCTAssertTrue(subject.zero)
        XCTAssertFalse(subject.negative)
        
    }
    
    func testSTAZeroPage() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        
        
        let memory = CPUMemory(ram: ram,
                               mapper: DebugReadOnlyPRGMapper(Data([0xA9,0x50,0x85,0x00,
                                                                    0xA9,0xFF,0x85,0x01,
                                                                    0xA9,0x00,0x85,0x02])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(ram[0],0x50)
        XCTAssertEqual(ram[1],0xFF)
        XCTAssertEqual(ram[2],0x00)

    }
}
