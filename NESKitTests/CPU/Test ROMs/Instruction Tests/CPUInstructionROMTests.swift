//
//  CPUInstructionROMTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPUInstructionROMTests: XCTestCase {
    var subject: Console!

    override func setUp() {
        super.setUp()
        subject = nil
    }
    
    func testOfficialInstructionROM() {
        
        let romURL = Bundle(for: CartridgeTests.self).url(forResource: "official_only", withExtension: "nes")!
        let romData = try! Data(contentsOf: romURL)
        
        let cartridge = try! Cartridge(data: romData)
        
        let console = Console(cartridge: cartridge)
        
        subject = console
        
        //FIXME: Actually run this
        
        for _ in 1...100 {
            step()
        }
        
        
    }
    
    private func step() {
        XCTAssertNoThrow(try subject.step())
//        print(String(format: "Test ROM State: %02X",getROMTestState(from: subject)))
        
        if let debugMessage = getROMDebugMessage(from: subject), debugMessage.isEmpty == false {
            print(debugMessage)
        }
    }
    
    private func getROMTestState(from console: Console) -> UInt8 {
        return console.cpu.memory.read(0x6000)
    }
    
    private func getROMDebugMessage(from console: Console) -> String? {
        
        var addr: UInt16 = 0x6004
        
        var bytes: [UInt8] = []
        
        var value = console.cpu.memory.read(addr)
        
        while value != 0 {
            bytes.append(value)
            addr+=1
            value = console.cpu.memory.read(addr)
        }
        
        return String(bytes: bytes, encoding: .ascii)
    }
}
