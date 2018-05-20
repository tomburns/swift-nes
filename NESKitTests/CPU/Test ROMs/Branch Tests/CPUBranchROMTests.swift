//
//  CPUBranchROMTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CPUBranchROMTests: XCTestCase {
    var subject: CPU6502!

    override func setUp() {
        super.setUp()
        subject = nil
    }

    func testBranchBasicsROM() {

        let romURL = Bundle(for: CartridgeTests.self).url(forResource: "1.Branch_Basics", withExtension: "nes")!
        let romData = try! Data(contentsOf: romURL)

        let cartridge = try! Cartridge(data: romData)

        let console = Console(cartridge: cartridge)

        subject = console.cpu

        //FIXME: Actually run this
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
        XCTAssertNoThrow(try subject.step())
    }

}
