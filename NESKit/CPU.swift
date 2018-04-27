//
//  CPU.swift
//  NESKit
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

class CPU6502 {
    let memory: Memory
    
    var programCounter: UInt16 = 0
    
    var stackPointer: UInt8 = 0
    
    var accumulator: UInt8 = 0
    var registerX: UInt8 = 0
    var registerY: UInt8 = 0

    var negative: Bool {
        return flags.contains(.negative)
    }
    
    var zero: Bool {
        return flags.contains(.zero)
    }
    
    var overflow: Bool {
        return flags.contains(.overflow)
    }
    
    var decimalMode: Bool {
        return flags.contains(.decimalMode)
    }
    
    var interruptDisable: Bool {
        return flags.contains(.interruptDisable)
    }
    
    var flags: StateFlags = []
    
    init(memory: Memory) {
        self.memory = memory
        reset()
    }
    
    @discardableResult
    func step() throws -> Int {
        let instruction = try nextInstruction()

        print(String(format:" %02X\t\t%@",programCounter, instruction.description))

        programCounter += UInt16(instruction.size)
        
        let (address,_) = getAddress(for: instruction)
        
        switch instruction.opcode {
        case .bit:
            bit(address)
        case .lda:
            lda(address)
        case .jsr:
            jsr(address)
        case .sei:
            sei()
        case .sta:
            sta(address)
        case .nop:
            break
        }
        
        return 1
    }
    
    func bit(_ address: UInt16) {
        let value = memory.read(address)
        
        setN(value)
        setV(value)
        setZ(value & accumulator)
    }
    
    func setZ(_ value: UInt8) {
        if value == 0 {
            flags.insert(.zero)
        } else {
            flags.remove(.zero)
        }
    }
    
    func setN(_ value: UInt8) {
        if (value  >> 7) > 0  {
            flags.insert(.negative)
        } else {
            flags.remove(.negative)
        }
    }
    
    func setV(_ value: UInt8) {
        if (value  >> 6) > 0 {
            flags.insert(.overflow)
        } else {
            flags.remove(.overflow)
        }
    }
    
    func lda(_ address: UInt16) {
        accumulator = memory.read(address)
        
        if accumulator == 0 {
            flags.insert(.zero)
        } else {
            flags.remove(.zero)
        }
        
        if accumulator.leadingZeroBitCount == 0 {
            flags.insert(.negative)
        } else {
            flags.remove(.negative)
        }
    }
    
    func jsr(_ address: UInt16) {
        push16(programCounter - 1)
        programCounter = address
    }
    
    func sei() {
        flags.insert(.interruptDisable)
    }
    
    func sta(_ address: UInt16) {
        memory.write(accumulator, to: address)
    }
    
    func push(_ value: UInt8) {
        memory.write(value, to: 0x100|UInt16(stackPointer))
        stackPointer -= 1
    }
    
    func push16(_ value: UInt16) {
        push(UInt8(value >> 8))
        push(UInt8(value & 0xFF))
    }
    
    private func nextInstruction() throws -> Instruction {
        let opcodeByte = memory.read(programCounter)
        let size = try Opcode.size(for: opcodeByte)
        
        let bytes = (UInt16(0)..<UInt16(size)).map { memory.read($0 + programCounter) }
        
        let instruction = try Instruction(Data(bytes), location: programCounter)
        
        return instruction
    }
    
    private func getAddress(for instruction: Instruction) -> (address: UInt16, pageCrossed: Bool) {
        let address: UInt16
        //FIXME: Not doing pageCrossed checks yet
        var pageCrossed = false
        
        
        switch instruction.operand {
        case let .absolute(addr):
            address = addr
        case let .absoluteX(offset):
            address = UInt16(registerX) + offset
        case let .absoluteY(offset):
            address = UInt16(registerY) + offset
        case .accumulator:
            fatalError()
            break
        case .immediate:
            address = instruction.location + 1
        case .implied:
            address = instruction.location
            break
        case let .indexedIndirect(offset):
            address = memory.read16(UInt16(registerX) + UInt16(offset))
        case let .indirect(addr):
            address = memory.read16(addr)
        case let .indirectIndexed(offset):
            address = memory.read16(UInt16(offset)) + UInt16(registerX)
        case let .relative(offset):
            if offset < 0x80 {
                address = UInt16(programCounter) + 2 + UInt16(offset)
            } else {
                address = UInt16(programCounter) + 2 + UInt16(offset) - 0x100
            }
        case let .zeroPage(addr):
            address = UInt16(addr)
        case let .zeroPageX(addr):
            address = UInt16(addr + registerX)
        case let .zeroPageY(addr):
            address = UInt16(addr + registerY)
        }
        
        return (address, pageCrossed)
    }
    
    
    func reset() {
        programCounter = memory.read16(0xFFFC)
        stackPointer = 0xFD
        flags = .initialState
    }
    
    enum Interrupt: Int {
        case none
        case nmi
        case irq
    }
    
    struct StateFlags: OptionSet, Codable {
        let rawValue: UInt8
        
        static let initialState = StateFlags(rawValue: 0x24)
        
        static let carry = StateFlags(rawValue: 1 << 0)
        static let zero = StateFlags(rawValue: 1 << 1)
        static let interruptDisable = StateFlags(rawValue: 1 << 2)
        static let decimalMode = StateFlags(rawValue: 1 << 3)
        static let breakCommand = StateFlags(rawValue: 1 << 4)
        static let unused = StateFlags(rawValue: 1 << 5)
        static let overflow = StateFlags(rawValue: 1 << 6)
        static let negative = StateFlags(rawValue: 1 << 7)
    }
}

