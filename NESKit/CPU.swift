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
    
    var cycles: Int = 0
    
    var programCounter: UInt16 = 0
    
    var stackPointer: UInt8 = 0
    
    var accumulator: UInt8 = 0
    var registerX: UInt8 = 0
    var registerY: UInt8 = 0
    
    var carry: Bool {
        return flags.contains(.carry)
    }
    
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
        
        let address = operandAddress(for: instruction)
        
        switch instruction.opcode {
        case .adc:
            adc(address)
        case .brk:
            brk()
        case .beq:
            beq(instruction)
        case .bne:
            bne(instruction)
        case .bpl:
            bpl(instruction)
        case .bit:
            bit(address)
        case .lda:
            lda(address)
        case .ldx:
            ldx(address)
        case .jsr:
            jsr(address)
        case .sei:
            sei()
        case .sta:
            sta(address)
        case .nop:
            break
        case .pha:
            pha()
        case .tax:
            tax()
        case .txa:
            txa()
        case .dex:
            dex()
        case .inx:
            inx()
        case .tay:
            tay()
        case .tya:
            tya()
        case .dey:
            dey()
        case .iny:
            iny()
        case .jmp:
            jmp(address)
        case .php:
            php()
        case .rol:
            rol(instruction)
        case .ror:
            ror(instruction)
        case .inc:
            inc(address)
        }
        
        return 1
    }
    
    func adc(_ address: UInt16) {
        print("maybe consider implementing ADC")
    }
    
    func inc(_ address: UInt16) {
        let value = memory.read(address) + 1
        
        memory.write(value, to: address)
        setZ(value)
        setN(value)
    }
    
    func beq(_ instruction: Instruction) {
        if !zero {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }
    
    func bit(_ address: UInt16) {
        let value = memory.read(address)
        
        setN(value)
        setV(value)
        setZ(value & accumulator)
    }
    
    func bne(_ instruction: Instruction) {
        if zero {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }
    
    func bpl(_ instruction: Instruction) {
        if !negative {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }
    
    func brk() {
        push16(programCounter)
        php()
        sei()
        programCounter = memory.read16(0xFFFE)
    }
    
    func rol(_ instruction: Instruction) {
        switch instruction.operand {
        case .accumulator:
            let carried: UInt8 = carry ? 1 : 0
            
            if (accumulator >> 7) & 1 == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }
            
            accumulator = (accumulator << 1 ) | carried
            setZ(accumulator)
            setN(accumulator)
        default:
            let address = operandAddress(for: instruction)
            let initial = memory.read(address)
            let carried: UInt8 = carry ? 1 : 0
            
            if (initial >> 7) & 1 == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }
            
            let value = (initial << 1 | carried)
            
            memory.write(value, to: address)
            setZ(value)
            setN(value)
        }
    }
    
    func ror(_ instruction: Instruction) {
        switch instruction.operand {
        case .accumulator:
            let carried: UInt8 = carry ? 1 : 0
            
            if (accumulator & 1) == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }
            
            accumulator = (accumulator >> 1 ) | (carried << 7)
            setZ(accumulator)
            setN(accumulator)
        default:
            let address = operandAddress(for: instruction)
            let initial = memory.read(address)
            let carried: UInt8 = carry ? 1 : 0
            
            if (initial >> 7) & 1 == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }
            
            let value = (initial >> 1)  | (carried << 7)
            
            memory.write(value, to: address)
            setZ(accumulator)
            setN(accumulator)
        }
    }
    
    func pha() {
        push(accumulator)
    }
    
    func php() {
        push(flags.rawValue | 0x10)
    }
    
    func tax() {
        registerX = accumulator
    }
    
    func txa() {
        accumulator = registerX
    }
    
    func dex() {
        registerX -= 1
    }
    
    func inx() {
        registerX += 1
    }
    
    func tay() {
        registerY = accumulator
    }
    
    func tya() {
        accumulator = registerY
    }
    
    func iny() {
        registerY += 1
    }
    
    func dey() {
        registerY -= 1
    }
    
    private func addBranchCycles(for instruction: Instruction) {
        cycles += 1
        
        if pagesDiffer(instruction.location, operandAddress(for: instruction)) {
            cycles += 1
        }
    }
    
    func pagesDiffer(_ a: UInt16, _ b: UInt16) -> Bool {
        return a&0xFF00 != b&0xFF00
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
    
    func ldx(_ address: UInt16) {
        registerX = memory.read(address)
        
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
    
    func jmp(_ address: UInt16) {
        push16(programCounter - 1)
        programCounter = address
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
    
    private func operandAddress(for instruction: Instruction) -> UInt16 {
        let address: UInt16
        
        switch instruction.operand {
        case let .absolute(addr):
            address = addr
        case let .absoluteX(offset):
            address = UInt16(registerX) + offset
        case let .absoluteY(offset):
            address = UInt16(registerY) + offset
        case .accumulator:
            address = instruction.location
        case .immediate:
            address = instruction.location + 1
        case .implied:
            address = instruction.location
        case let .indexedIndirect(offset):
            address = memory.read16(UInt16(registerX) + UInt16(offset))
        case let .indirect(addr):
            address = memory.read16(addr)
        case let .indirectIndexed(offset):
            address = memory.read16(UInt16(offset)) + UInt16(registerX)
        case let .relative(offset):
            if offset < 0x80 {
                address = UInt16(instruction.location) + 2 + UInt16(offset)
            } else {
                address = UInt16(instruction.location) + 2 + UInt16(offset) - 0x100
            }
        case let .zeroPage(addr):
            address = UInt16(addr)
        case let .zeroPageX(addr):
            address = UInt16(addr + registerX)
        case let .zeroPageY(addr):
            address = UInt16(addr + registerY)
        }
        
        return address
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

