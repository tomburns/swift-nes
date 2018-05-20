//
//  NESTestROMTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class NESTestROMTests: XCTestCase {
    var subject: Console!

    override func setUp() {
        super.setUp()
        subject = nil
    }

    func testNESTestROM() {

        let romURL = Bundle(for: CartridgeTests.self).url(forResource: "nestest", withExtension: "nes")!
        let romData = try! Data(contentsOf: romURL)

        let cartridge = try! Cartridge(data: romData)

        let console = Console(cartridge: cartridge)

        subject = console

        subject.cpu.programCounter = 0xC000
        //FIXME: Actually run this

        runROM()

    }

    private func runROM() {
        var stop = false
        while !stop {
            do {
                try subject.step()
            } catch {
                XCTFail("\(error)")
                stop = true
            }

            if stop { break }
        }

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
