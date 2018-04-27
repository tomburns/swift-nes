//
//  CPU6502Tests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/26/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPU6502Tests: XCTestCase {

    var subject: CPU6502!
    
    override func setUp() {
        super.setUp()
        subject = nil
    }

   
    
    func testInitialState() {
        let memory = CPUMemory(ram: UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                                           alignment: 1),
                               mapper: DebugReadOnlyPRGMapper(Data([0xA9,0xFF])))
        
        subject = CPU6502(memory: memory)
        
        XCTAssertEqual(subject.programCounter, 0x8000)
        XCTAssertEqual(subject.stackPointer, 0xFD)
        XCTAssertFalse(subject.decimalMode)
        XCTAssertTrue(subject.interruptDisable)
        
        XCTAssertNoThrow(try subject.step())

        subject.reset()
        
        XCTAssertEqual(subject.programCounter, 0x8000)
        XCTAssertEqual(subject.stackPointer, 0xFD)
        XCTAssertFalse(subject.decimalMode)
        XCTAssertTrue(subject.interruptDisable)
        
    }
}

struct DummyMapper: Mapper {
    func read(_ address: UInt16) -> UInt8 {
        fatalError()
    }
    
    func write(_ value: UInt8, to address: UInt16) {
        fatalError()
    }
    
    func step() {
        fatalError()
    }
}

struct DebugReadOnlyPRGMapper: Mapper {
    let prg: Data
    
    init(_ data: Data) {
        var data = data
        data.append(contentsOf: Array<UInt8>.init(repeating: 0, count: 2048 - data.count))
       
        self.prg = data
    }
    
    func read(_ address: UInt16) -> UInt8 {
        guard address >= 0x8000 else {
            fatalError("unsupported DebugReadOnlyPRGMapper read at \(address)")
        }
        
        
        if address == 0xFFFC {
            return 0x00
        }
        
        if address == 0xFFFD {
            return 0x80
        }
        
        let prgAddress = Int(address - 0x8000)

        
        return prg[prgAddress]
    }
    
    func write(_ value: UInt8, to address: UInt16) {
        fatalError()
    }
    
    func step() {
        
    }
}
