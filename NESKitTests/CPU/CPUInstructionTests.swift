//
//  CPUInstructionTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPUInstructionTests: XCTestCase {
    var subject: CPU6502!
    
    override func setUp() {
        super.setUp()
        subject = nil
    }

    func testLDAImmediate() {
        let ppu = PPU()
        
        let memory = CPUMemory(ram: UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                                           alignment: 1),
                               ppu: ppu,
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
                               ppu: PPU(),
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
    
    func testBITZeroPage() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        
        ram[0] = 0x00
        ram[1] = 0xC3
        ram[2] = 0xFF
        
        let memory = CPUMemory(ram: ram,
                               ppu: PPU(),
                               mapper: DebugReadOnlyPRGMapper(Data([0x24,0x00,
                                                                    0x24,0x01,
                                                                    0x24,0x02,
                                                                    0xA9,0x11,
                                                                    0x24,0x02,])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertFalse(subject.negative)
        XCTAssertTrue(subject.zero)
        XCTAssertFalse(subject.overflow)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertTrue(subject.negative)
        XCTAssertTrue(subject.zero)
        XCTAssertTrue(subject.overflow)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertTrue(subject.negative)
        XCTAssertTrue(subject.zero)
        XCTAssertTrue(subject.overflow)
        
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertTrue(subject.negative)
        XCTAssertFalse(subject.zero)
        XCTAssertTrue(subject.overflow)
    }
    
    func testSEI() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        let memory = CPUMemory(ram: ram,
                               ppu: PPU(),
                               mapper: DebugReadOnlyPRGMapper(Data([0x78])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertTrue(subject.interruptDisable)
    }
    
    func testBEQ() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        let memory = CPUMemory(ram: ram,
                               ppu: PPU(),
                               mapper: DebugReadOnlyPRGMapper(Data([0xF0, 0x02, 0xA9, 0x99, 0xA9, 0xEE])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())

        XCTAssertEqual(0xEE, subject.accumulator)
    }
    
    func testBPLNoBranch() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        let memory = CPUMemory(ram: ram,
                               ppu: PPU(),
                               mapper: DebugReadOnlyPRGMapper(Data([0xA9, 0xEF, 0x78, 0x10, 0x02, 0xA9, 0x99, 0xA9, 0xEE])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(0x99, subject.accumulator)
    }
    
    func testBPLBranch() {
        let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                         alignment: 1)
        let memory = CPUMemory(ram: ram,
                               ppu: PPU(),
                               mapper: DebugReadOnlyPRGMapper(Data([0xA9, 0x03, 0x78, 0x10, 0x02, 0xA9, 0x99, 0xA9, 0xEE])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        
        XCTAssertEqual(0xEE, subject.accumulator)
    }
}
