//
//  InstructionTests.swift
//  NESKitTests
//
//  Created by Tom Burns on 4/26/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import XCTest

@testable import NESKit

class InstructionTests: XCTestCase {
    
    func testLDAImmediate() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xA9, 0x23]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA #$23")
    }
    
    func testLDAZeroPage() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xA5, 0x45]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA $45")
    }
    
    func testLDAZeroPageX() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xB5, 0x67]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA $67,X")
    }
    
    func testLDAAbsolute() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xAD, 0x89, 0xAB]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA $AB89")
    }
    
    func testLDAAbsoluteX() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xBD, 0xCD, 0xEF]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA $EFCD,X")
    }
    
    func testLDAAbsoluteY() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xB9, 0x01, 0x23]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA $2301,Y")
    }
    
    func testLDAIndirectIndexed() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xB1, 0x86]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA ($86),Y")
    }
    
    func testLDAIndexedIndirect() {
        let subject = try! CPU6502.Instruction(Data(bytes: [0xA1, 0x69]))
        XCTAssertEqual(subject.opcode, .lda)
        XCTAssertEqual(subject.description, "LDA ($69,X)")
    }
    
    
}
