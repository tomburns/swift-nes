//
//  CPU.swift
//  NESKit
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

//swiftlint:disable type_body_length file_length
class CPU6502 {
    let memory: Memory

    var cycles: Int = 0

    var programCounter: UInt16 = 0

    var stackPointer: UInt8 = 0

    var accumulator: UInt8 = 0
    var registerX: UInt8 = 0
    var registerY: UInt8 = 0

    var interrupt: Interrupt = .none

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
    // swiftlint:disable cyclomatic_complexity function_body_length
    func step() throws -> Int {

        switch interrupt {
        case .nmi:
            nmi()
        case .irq:
            irq()
        case .none:
            break
        }

        interrupt = .none

        let instruction = try nextInstruction()

        print(cpuStateDescription(nextInstruction: instruction))

        let opcode = Int(instruction.data[0])

        programCounter += UInt16(instruction.size)

        let previousCycles = cycles

        let pagesCrossed: Bool
        switch instruction.operand {
        case let .absoluteX(address):
            pagesCrossed = pagesDiffer(address - UInt16(registerX), address)
        case let .absoluteY(address):
            pagesCrossed = pagesDiffer(address - UInt16(registerY), address)
        case .indirectIndexed:
            let address = memory.read16Bug(UInt16(memory.read(programCounter+1))) + UInt16(registerY)
            pagesCrossed = pagesDiffer(address - UInt16(registerY), address)
        default:
            pagesCrossed = false
        }

        cycles += Opcode.cycles[opcode]

        if pagesCrossed {
            cycles += Opcode.pageCycles[opcode]
        }

        let address = operandAddress(for: instruction)

        switch instruction.opcode {
        case .asl:
            asl(instruction)
        case .sty:
            sty(instruction)
        case .adc:
            adc(instruction)
        case .eor:
            eor(instruction)
        case .clv:
            clv()
        case .cld:
            cld()
        case .cmp:
            cmp(instruction)
        case .and:
            and(instruction)
        case .brk:
            brk()
        case .beq:
            beq(instruction)
        case .bne:
            bne(instruction)
        case .bpl:
            bpl(instruction)
        case .bcs:
            bcs(instruction)
        case .bcc:
            bcc(instruction)
        case .bit:
            bit(address)
        case .bvs:
            bvs(instruction)
        case .lda:
            lda(address)
        case .ldx:
            ldx(address)
        case .ldy:
            ldy(instruction)
        case .cpx:
            cpx(instruction)
        case .cpy:
            cpy(instruction)
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
            inc(instruction)
        case .lsr:
            lsr(instruction)
        case .dec:
            dec(instruction)
        case .rti:
            rti()
        case .stx:
            stx(instruction)
        case .sec:
            sec()
        case .clc:
            clc()
        case .bmi:
            bmi(instruction)
        case .bvc:
            bvc(instruction)
        case .rts:
            rts()
        case .sed:
            sed()
        case .pla:
            pla()
        case .txs:
            txs()
        case .tsx:
            tsx()
        case .plp:
            plp()
        case .ora:
            ora(instruction)
        case .sbc:
            sbc(instruction)
        case .lax:
            lax(instruction)
        case .sax:
            sax(instruction)
        case .dcp:
            dcp(instruction)
        case .isc:
            isc(instruction)
        case .slo:
            slo(instruction)
        case .rla:
            rla(instruction)
        case .sre:
            sre(instruction)
        case .rra:
            rra(instruction)
        }

        return cycles - previousCycles
    }

    func and(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))
        accumulator &= value

        setZ(accumulator)
        setN(accumulator)
    }

    func ora(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))
        accumulator |= value

        setZ(accumulator)
        setN(accumulator)
    }

    func cpx(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))

        compare(registerX, to: value)
    }

    func cpy(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))

        compare(registerY, to: value)
    }

    func dec(_ instruction: Instruction) {
        let address = operandAddress(for: instruction)
        let (value, _) = memory
            .read(address)
            .subtractingReportingOverflow(1)

        memory.write(value, to: address)

        setZ(value)
        setN(value)
    }

    func dcp(_ instruction: Instruction) {
        dec(instruction)
        cmp(instruction)
    }

    func adc(_ instruction: Instruction) {
        let a: UInt8 = accumulator
        let b: UInt8 = memory.read(operandAddress(for: instruction))
        let c: UInt8 = flags.contains(.carry) ? 1 : 0

        (accumulator, _) = a.addingReportingOverflow(b)
        (accumulator, _) = accumulator.addingReportingOverflow(c)

        if (a^b) & 0x80 == 0 && (a^accumulator) & 0x80 != 0 {
            flags.insert(.overflow)
        } else {
            flags.remove(.overflow)
        }

        setZ(accumulator)
        setN(accumulator)

        if (Int(a) + Int(b) + Int(c)) > 0xFF {
            flags.insert(.carry)
        } else {
            flags.remove(.carry)
        }
    }

    func sbc(_ instruction: Instruction) {
        let a: UInt8 = accumulator
        let b: UInt8 = memory.read(operandAddress(for: instruction))
        let c: UInt8 = flags.contains(.carry) ? 1 : 0

        accumulator = a
            .subtractingReportingOverflow(b).partialValue
            .subtractingReportingOverflow(1 - c).partialValue

        setZ(accumulator)
        setN(accumulator)

        if (Int(a) - Int(b) - Int(1 - c)) >= 0 {
            flags.insert(.carry)
        } else {
            flags.remove(.carry)
        }

        if (a^b) & 0x80 != 0 && (a^accumulator) & 0x80 != 0 {
            flags.insert(.overflow)
        } else {
            flags.remove(.overflow)
        }
    }

    func cmp(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))
        compare(accumulator, to: value)
    }

    func sec() {
        flags.insert(.carry)
    }

    func clc() {
        flags.remove(.carry)
    }

    func clv() {
        flags.remove(.overflow)
    }

    func asl(_ instruction: Instruction) {
        switch instruction.operand {
        case .accumulator:
            if (accumulator >> 7) & 1 == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }

            accumulator <<= 1

            setZ(accumulator)
            setN(accumulator)
        default:
            let address = operandAddress(for: instruction)
            var value = memory.read(address)

            if (value >> 7) & 1 == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }

            value <<= 1

            setZ(value)
            setN(value)

            memory.write(value, to: address)
        }
    }

    func eor(_ instruction: Instruction) {
        let value = memory.read(operandAddress(for: instruction))
        accumulator ^= value
        setZ(accumulator)
        setN(accumulator)
    }

    func stx(_ instruction: Instruction) {
        memory.write(registerX, to: operandAddress(for: instruction))
    }

    func sty(_ instruction: Instruction) {
        memory.write(registerY, to: operandAddress(for: instruction))
    }

    func pla() {
        accumulator = pull()
        setZ(accumulator)
        setN(accumulator)
    }

    func cld() {
        flags.remove(.decimalMode)
    }

    func txs() {
        stackPointer = registerX
    }

    func tsx() {
        registerX = stackPointer
        setZ(registerX)
        setN(registerX)
    }

    func plp() {
        setFlags(pull() & 0xEF | 0x20)
    }

    func inc(_ instruction: Instruction) {
        let address = operandAddress(for: instruction)

        let (value, _) = memory.read(address).addingReportingOverflow(1)

        memory.write(value, to: address)
        setZ(value)
        setN(value)
    }

    func beq(_ instruction: Instruction) {
        if zero {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bne(_ instruction: Instruction) {
        if !zero {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bmi(_ instruction: Instruction) {
        if negative {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bvc(_ instruction: Instruction) {
        if !overflow {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bit(_ address: UInt16) {
        let value = memory.read(address)

        setN(value)
        setZ(value & accumulator)

        if (value >> 6) & 1 == 1 {
            flags.insert(.overflow)
        } else {
            flags.remove(.overflow)
        }
    }

    func bpl(_ instruction: Instruction) {
        if !negative {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bcs(_ instruction: Instruction) {
        if carry {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bcc(_ instruction: Instruction) {
        if !carry {
            programCounter = operandAddress(for: instruction)
            addBranchCycles(for: instruction)
        }
    }

    func bvs(_ instruction: Instruction) {
        if overflow {
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

    func lsr(_ instruction: Instruction) {
        switch instruction.operand {
        case .accumulator:
            setC(accumulator)

            accumulator = accumulator >> 1
            setZ(accumulator)
            setN(accumulator)
        default:
            let address = operandAddress(for: instruction)
            let initial = memory.read(address)
            setC(initial)

            let result = initial >> 1
            memory.write(result, to: address)
            setZ(result)
            setN(result)
        }
    }

    func rts() {
        programCounter = pull16() + 1
    }

    func sed() {
        flags.insert(.decimalMode)
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

            if (initial & 1) == 1 {
                flags.insert(.carry)
            } else {
                flags.remove(.carry)
            }

            let value = (initial >> 1)  | (carried << 7)

            memory.write(value, to: address)
            setZ(value)
            setN(value)
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

        setZ(registerX)

    }

    func txa() {
        accumulator = registerX

        setZ(accumulator)
        setN(accumulator)
    }

    func dex() {
        (registerX, _) = registerX.subtractingReportingOverflow(1)

        setZ(registerX)
        setN(registerX)
    }

    func inx() {
        (registerX, _) = registerX.addingReportingOverflow(1)

        setZ(registerX)
        setN(registerX)
    }

    func tay() {
        registerY = accumulator

        setZ(registerY)

    }

    func tya() {
        accumulator = registerY

        setZ(accumulator)

    }

    func iny() {
        (registerY, _) = registerY.addingReportingOverflow(1)

        setZ(registerY)
        setN(registerY)
    }

    func dey() {
        (registerY, _) = registerY.subtractingReportingOverflow(1)

        setZ(registerY)
        setN(registerY)
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

    func setC(_ value: UInt8) {
        if value & 1 == 1 {
            flags.insert(.carry)
        } else {
            flags.remove(.carry)
        }
    }

    func setZ(_ value: UInt8) {
        if value == 0 {
            flags.insert(.zero)
        } else {
            flags.remove(.zero)
        }
    }

    func setN(_ value: UInt8) {
        if (value  >> 7) > 0 {
            flags.insert(.negative)
        } else {
            flags.remove(.negative)
        }
    }

    func setV(_ value: UInt8) {
        if (value  >> 6) >= 0 {
            flags.insert(.overflow)
        } else {
            flags.remove(.overflow)
        }
    }

    func lda(_ address: UInt16) {
        accumulator = memory.read(address)

        setZ(accumulator)
        setN(accumulator)
    }

    func ldx(_ address: UInt16) {
        registerX = memory.read(address)

        setZ(registerX)
        setN(registerX)
    }

    func ldy(_ instruction: Instruction) {
        registerY = memory.read(operandAddress(for: instruction))

        setZ(registerY)
        setN(registerY)
    }

    func jmp(_ address: UInt16) {
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

    func rti() {
        setFlags(pull() & 0xEF | 0x20)
        programCounter = pull16()
    }

    func lax(_ instruction: Instruction) {
        let address = operandAddress(for: instruction)
        lda(address)
        ldx(address)
    }

    func sax(_ instruction: Instruction) {
        let value = accumulator & registerX

        memory.write(value, to: operandAddress(for: instruction))
    }

    func isc(_ instruction: Instruction) {
        inc(instruction)
        sbc(instruction)
    }

    func slo(_ instruction: Instruction) {
        asl(instruction)
        ora(instruction)
    }

    func rla(_ instruction: Instruction) {
        rol(instruction)
        and(instruction)
    }

    func sre(_ instruction: Instruction) {
        lsr(instruction)
        eor(instruction)
    }

    func rra(_ instruction: Instruction) {
        ror(instruction)
        adc(instruction)
    }

    func nmi() {
        push16(programCounter)
        php()
        programCounter = memory.read16(0xFFFA)
        flags.insert(.interruptDisable)
        cycles += 7
    }

    func irq() {
        push16(programCounter)
        php()
        programCounter = memory.read16(0xFFFE)
        flags.insert(.interruptDisable)
        cycles += 7
    }

    func setFlags(_ byte: UInt8) {
        flags = StateFlags(rawValue: byte)
    }

    func push(_ value: UInt8) {
        memory.write(value, to: 0x100|UInt16(stackPointer))
        stackPointer = stackPointer.subtractingReportingOverflow(1).partialValue
    }

    func push16(_ value: UInt16) {
        push(UInt8(value >> 8))
        push(UInt8(value & 0xFF))
    }

    func pull() -> UInt8 {
        stackPointer = stackPointer.addingReportingOverflow(1).partialValue
        return memory.read(0x100|UInt16(stackPointer))
    }

    func pull16() -> UInt16 {
        let low = UInt16(pull())
        let high = UInt16(pull())

        return high << 8 | low
    }

    private func nextInstruction() throws -> Instruction {
        let opcodeByte = memory.read(programCounter)
        let size = Opcode.sizes[Int(opcodeByte)]

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
            address = UInt16(registerX).addingReportingOverflow(UInt16(offset)).partialValue
        case let .absoluteY(offset):
            address = UInt16(registerY).addingReportingOverflow(UInt16(offset)).partialValue
        case .accumulator:
            address = instruction.location
        case .immediate:
            address = instruction.location.addingReportingOverflow(1).partialValue
        case .implied:
            address = instruction.location
        case let .indexedIndirect(offset):
            // uint16(cpu.Read(cpu.PC+1) + cpu.X)
            address = memory.read16Bug(UInt16(offset.addingReportingOverflow(registerX).partialValue))
        case let .indirect(addr):
            address = memory.read16Bug(addr)
        case let .indirectIndexed(offset):
            address = memory.read16Bug(UInt16(offset)).addingReportingOverflow(UInt16(registerY)).partialValue
        case let .relative(offset):
            if offset < 0x80 {
                address = UInt16(instruction.location) + 2 + UInt16(offset)
            } else {
                address = UInt16(instruction.location) + 2 + UInt16(offset) - 0x100
            }
        case let .zeroPage(addr):
            address = UInt16(addr)
        case let .zeroPageX(addr):
            address = UInt16(addr.addingReportingOverflow(registerX).partialValue)
        case let .zeroPageY(addr):
            address = UInt16(addr.addingReportingOverflow(registerY).partialValue)
        }

        return address
    }

    func reset() {
        programCounter = memory.read16(0xFFFC)
        stackPointer = 0xFD
        flags = .initialState
    }

    private func compare(_ rhs: UInt8, to lhs: UInt8) {
        let value = rhs.subtractingReportingOverflow(lhs).partialValue

        setZ(value)
        setN(value)

        if rhs >= lhs {
            flags.insert(.carry)
        } else {
            flags.remove(.carry)
        }
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

    func cpuStateDescription(nextInstruction instruction: Instruction) -> String {

        let cursor = String(format: "%04X  ", programCounter)

        let bytes = instruction.data.map { String(format: "%02X ", $0) }
            .joined()
            .padding(toLength: 10, withPad: " ", startingAt: 0)

        let stateInfo = String(format: "A:%02X X:%02X Y:%02X P:%02X SP:%02X CYC:%03d",
                               accumulator,
                               registerX,
                               registerY,
                               flags.rawValue,
                               stackPointer,
                               (cycles * 3) % 341)
            .padding(toLength: 33, withPad: " ", startingAt: 0)

        return (cursor + bytes + instruction.description).padding(toLength: 48, withPad: " ", startingAt: 0) + stateInfo
    }
}
