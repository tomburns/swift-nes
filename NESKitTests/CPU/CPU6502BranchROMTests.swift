//
//  CPU6502BranchROMTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPU6502BranchROMTests: XCTestCase {
    var subject: CPU6502!

    override func setUp() {
        super.setUp()
        subject = nil
    }
    
    func testBranchBasicsROM() {
        
        let romURL = Bundle(for: CartridgeTests.self).url(forResource: "1.Branch_Basics", withExtension: "nes")!
        let romData = try! Data(contentsOf: romURL)
        
        let cartridge = try! Cartridge(data: romData)
        
        let memory = CPUMemory(ram: UnsafeMutableRawBufferPointer.allocate(byteCount: 2048,
                                                                           alignment: 1),
                               mapper: NROM128Mapper(cartridge: cartridge))
        
        subject = CPU6502(memory: memory)
        
        //FIXME: Actually run this
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
//        XCTAssertNoThrow(try subject.step())
    }
    
}

