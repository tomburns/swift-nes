//
//  CartridgeTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class CartridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValidImport() {

        let romURL = Bundle(for: CartridgeTests.self).url(forResource: "nestest", withExtension: "nes")!
        let romData = try! Data(contentsOf: romURL)

        let subject = try! Cartridge(data: romData)

        XCTAssertEqual(0, subject.mapperValue)

        print(subject)

    }

    func testMapperValueFromValidHeader() {
        let romData = Data(bytes: [78, 69, 83, 26, 0, 0, 0x41, 0x27, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        let subject = try! Cartridge(data: romData)

        print(subject)

        XCTAssertEqual(36, subject.mapperValue)
    }

}
