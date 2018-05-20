//
//  DecompilerTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/25/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class DecompilerTests: XCTestCase {

    func testLDAInstructions() {
        let subject = CPU6502.Decompiler { print($0) }

        let result = try? subject.parse(
            Data(bytes: [0xA9, 0x23, 0xA5, 0x45, 0xB5,
                         0x67, 0xAD, 0x89, 0xAB, 0xBD,
                         0xCD, 0xEF, 0xB9, 0x01, 0xA1,
                         0xB1, 0x86, 0xA1, 0x69]))

        XCTAssertEqual(result, ldaExpected)

        print(result ?? "Failed to parse in \(#function)")

    }
}

private let ldaExpected = """
LDA #$23
LDA $45
LDA $67,X
LDA $AB89
LDA $EFCD,X
LDA $A101,Y
LDA ($86),Y
LDA ($69,X)

"""
