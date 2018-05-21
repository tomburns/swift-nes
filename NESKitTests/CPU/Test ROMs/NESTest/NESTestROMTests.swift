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

        runROM()
    }

    private func runROM() {
        var stop = false
        while subject.cpu.stackPointer != 0xFF {
            do {
                try subject.step()
            } catch {
                XCTFail("\(error)")
                stop = true
            }

            if stop { break }
        }

        print("Test ROM exit codes:", getROMTestState(from: subject))
    }

    private func getROMTestState(from console: Console) -> (UInt8,UInt8) {
        return (console.cpu.memory.read(0x0002),console.cpu.memory.read(0x0003))
    }
}
