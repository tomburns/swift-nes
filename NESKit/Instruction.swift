//
//  Instruction.swift
//  NESKit
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

extension CPU6502 {
    enum Opcode: String, Codable {
        case adc = "ADC"
        case bit = "BIT"
        case cmp = "CMP"
        case lda = "LDA"
        case ldx = "LDX"
        case ldy = "LDY"
        case nop = "NOP"
        case jsr = "JSR"
        case sei = "SEI"
        case sta = "STA"
        case jmp = "JMP"
        case brk = "BRK"
        case rol = "ROL"
        case ror = "ROR"
        case inc = "INC"
        case lsr = "LSR"
        case rti = "RTI"

        //Branch Instructions
        case bpl = "BPL"
        case beq = "BEQ"
        case bne = "BNE"
        case bvs = "BVS"
        case bcs = "BCS"
        case bcc = "BCC"
        case bmi = "BMI"
        case bvc = "BVC"

        //Register Instructions
        case tax = "TAX"
        case txa = "TXA"
        case dex = "DEX"
        case inx = "INX"
        case tay = "TAY"
        case tya = "TYA"
        case dey = "DEY"
        case iny = "INY"

        //Stack Instructions
        case txs = "TXS"
        case tsx = "TSX"
        case pha = "PHA"
        case pla = "PLA"
        case php = "PHP"
        case plp = "PLP"

        case stx = "STX"
        case sty = "STY"

        case sec = "SEC"
        case clc = "CLC"

        case rts = "RTS"

        case sed = "SED"
        case cld = "CLD"

        case and = "AND"
        case ora = "ORA"
        case eor = "EOR"

        case sbc = "SBC"

        case clv = "CLV"

        case cpx = "CPX"
        case cpy = "CPY"

        // swiftlint:disable cyclomatic_complexity function_body_length
        init(_ byte: UInt8) throws {
            switch byte {
            case 0xE9, 0xE5, 0xF5, 0xED, 0xFD, 0xF9, 0xE1, 0xF1:
                self = .sbc
            case 0xD8:
                self = .cld
            case 0x49, 0x45, 0x55, 0x4D, 0x5D, 0x59, 0x41, 0x51:
                self = .eor
            case 0x09, 0x05, 0x15, 0x0D, 0x1D, 0x19, 0x01, 0x11:
                self = .ora
            case 0x29, 0x25, 0x35, 0x2D, 0x3D, 0x39, 0x21, 0x31:
                self = .and
            case 0xC9, 0xC5, 0xD5, 0xCD, 0xDD, 0xD9, 0xC1, 0xD1:
                self = .cmp
            case 0xF8:
                self = .sed
            case 0x60:
                self = .rts
            case 0x90:
                self = .bcc
            case 0x18:
                self = .clc
            case 0xB0:
                self = .bcs
            case 0x38:
                self = .sec
            case 0xEA:
                self = .nop
            case 0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71:
                self = .adc
            case 0x00:
                self = .brk
            case 0x9A:
                self = .txs
            case 0xBA:
                self = .tsx
            case 0x48:
                self = .pha
            case 0x68:
                self = .pla
            case 0x08:
                self = .php
            case 0x28:
                self = .plp
            case 0x10:
                self = .bpl
            case 0xF0:
                self = .beq
            case 0xD0:
                self = .bne
            case 0x70:
                self = .bvs
            case 0x24, 0x2C:
                self = .bit
            case 0xE6, 0xF6, 0xEE, 0xFE:
                self = .inc
            case 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1:
                self = .lda
            case 0x4A, 0x46, 0x56, 0x4E, 0x5E:
                self = .lsr
            case 0x20:
                self = .jsr
            case 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91:
                self = .sta
            case 0x78:
                self = .sei
            case 0xA2, 0xA6, 0xB6, 0xAE, 0xBE:
                self = .ldx
            case 0xA0, 0xA4, 0xB4, 0xAC, 0xBC:
                self = .ldy
            case 0xAA:
                self = .tax
            case 0x8A:
                self = .txa
            case 0xCA:
                self = .dex
            case 0x40:
                self = .rti
            case 0xE8:
                self = .inx
            case 0xA8:
                self = .tay
            case 0x98:
                self = .tya
            case 0x88:
                self = .dey
            case 0xC8:
                self = .iny
            case 0x4C, 0x6C:
                self = .jmp
            case 0x2A, 0x26, 0x36, 0x2E, 0x3E:
                self = .rol
            case 0x6A, 0x66, 0x76, 0x6E, 0x7E:
                self = .ror
            case 0x86, 0x96, 0x8E:
                self = .stx
            case 0x84, 0x94, 0x8C:
                self = .sty
            case 0x30:
                self = .bmi
            case 0x50:
                self = .bvc
            case 0xB8:
                self = .clv
            case 0xE0, 0xE4, 0xEC:
                self = .cpx
            case 0xC0, 0xC4, 0xCC:
                self = .cpy
            default:
                throw Error.unsupportedOpcode(byte)
            }
        }

        static func size(for opcode: UInt8) throws -> Int {
            switch opcode {
            case 0xB8, 0xD8, 0x9A, 0xBA, 0x48, 0x68, 0x08,
                 0x28, 0xF8, 0x60, 0x18, 0x38, 0xEA, 0x40,
                 0x4A, 0x6A, 0x2A, 0x00, 0x78, 0xAA, 0x8A,
                 0xCA, 0xE8, 0xA8, 0x98, 0x88, 0xC8:
                return 1
            case 0x84, 0x94, 0xE9, 0xE5, 0xF5, 0xE1, 0xF1,
                 0xC0, 0xC4, 0xE0, 0xE4, 0xA0, 0xA4, 0xB4,
                 0x69, 0x65, 0x75, 0x61, 0x71, 0x49, 0x45,
                 0x55, 0x41, 0x51, 0x09, 0x05, 0x15, 0x01,
                 0x11, 0xC9, 0xC5, 0xD5, 0xC1, 0xD1, 0x29,
                 0x25, 0x35, 0x21, 0x31, 0x30, 0x50, 0x90,
                 0xB0, 0x86, 0x96, 0x70, 0x46, 0x56, 0xE6,
                 0xF6, 0x66, 0x76, 0x26, 0x36, 0x10, 0xF0,
                 0x24, 0x81, 0x91, 0x85, 0x95, 0xA1, 0xB1,
                 0xA9, 0xA5, 0xB5, 0xA2, 0xA6, 0xB6, 0xD0:
                return 2
            case 0x8C, 0xED, 0xFD, 0xF9, 0xEC, 0xCC, 0xAC,
                 0xBC, 0x6D, 0x7D, 0x79, 0x4D, 0x5D, 0x59,
                 0x0D, 0x1D, 0x19, 0xCD, 0xDD, 0xD9, 0x2D,
                 0x3D, 0x39, 0x8E, 0x4E, 0x5E, 0x6E, 0x7E,
                 0x2E, 0x3E, 0x2C, 0xAD, 0xBD, 0xB9, 0x20,
                 0x8D, 0x9D, 0x99, 0xAE, 0xBE, 0x4C, 0x6C,
                 0xEE, 0xFE:
                return 3
            default:
                throw Error.unsupportedOpcode(opcode)
            }
        }
    }

    struct Instruction {
        let location: UInt16

        let opcode: Opcode
        let operand: Operand

        var size: Int {
            return data.count
        }

        let data: Data

        init(_ data: Data, location: UInt16 = 0x0000) throws {
            self.data = data
            self.location = location

            guard data.count > 0 else {
                throw Error.invalidInstruction
            }

            opcode = try Opcode(data[0])

            operand = try Operand(data)

        }

        enum Operand {
            case absolute(UInt16)
            case absoluteX(UInt16)
            case absoluteY(UInt16)
            case accumulator
            case immediate(UInt8)
            case implied
            case indexedIndirect(UInt8)
            case indirect(UInt16)
            case indirectIndexed(UInt8)
            case relative(UInt8)
            case zeroPage(UInt8)
            case zeroPageX(UInt8)
            case zeroPageY(UInt8)

            init(_ data: Data) throws {
                guard data.count > 0 else {
                    self = .implied
                    return
                }

                switch data[0] {
                case 0xE9, 0xE0, 0xC0, 0xA0, 0x49, 0x09,
                     0xC9, 0x29, 0x69, 0xA9, 0xA2:
                    self = .immediate(data[1])
                case 0x84, 0xE5, 0xE4, 0xC4, 0xA4, 0x45,
                     0x05, 0xC5, 0x25, 0x86, 0x46, 0xE6,
                     0x65, 0x26, 0xA5, 0x85, 0x24, 0xA6,
                     0x66:
                    self = .zeroPage(data[1])
                case 0x94, 0xF5, 0xB4, 0x55, 0x15, 0xD5,
                     0x35, 0x56, 0xF6, 0x75, 0x36, 0xB5,
                     0x95, 0x76:
                    self = .zeroPageX(data[1])
                case 0x96, 0xB6:
                    self = .zeroPageY(data[1])
                case 0x8C, 0xED, 0xEC, 0xCC, 0xAC, 0x4D,
                     0x0D, 0xCD, 0x2D, 0x8E, 0x4E, 0xEE,
                     0x6D, 0x2E, 0xAD, 0x8D, 0x20, 0x2C,
                     0xAE, 0x4C, 0x6E:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absolute(address)
                case 0xFD, 0xBC, 0x5D, 0x1D, 0xDD, 0x3D,
                     0x5E, 0xFE, 0x7D, 0x3E, 0xBD, 0x9D,
                     0x7E:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteX(address)
                case 0xF9, 0x59, 0x19, 0xD9, 0x39, 0x79,
                     0xB9, 0x99, 0xBE:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteY(address)
                case 0x6C:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .indirect(address)
                case 0xE1, 0x41, 0x01, 0xC1, 0x21, 0x61,
                     0xA1, 0x81:
                    self = .indexedIndirect(data[1])
                case 0xF1, 0x51, 0x11, 0xD1, 0x31, 0x71,
                     0xB1, 0x91:
                    self = .indirectIndexed(data[1])
                case 0xB8, 0xD8, 0xF8, 0x60, 0x18, 0x38,
                     0xEA, 0x40, 0x00, 0x78, 0x9A, 0xBA,
                     0x48, 0x68, 0x08, 0x28, 0xAA, 0x8A,
                     0xCA, 0xE8, 0xA8, 0x98, 0x88, 0xC8:
                    self = .implied
                case 0x30, 0x50, 0xD0, 0x90, 0xB0, 0x70,
                     0xF0, 0x10:
                    self = .relative(data[1])
                case 0x4A, 0x2A, 0x6A:
                    self = .accumulator
                default:
                    throw Error.unsupportedOpcode(data[0])
                }
            }
        }
    }

    enum Error: Swift.Error {
        case unsupportedOpcode(UInt8)
        case invalidInstruction
    }
}

extension CPU6502.Instruction {

}

extension CPU6502.Instruction: CustomStringConvertible {
    var description: String {
        return "\(opcode.rawValue) \(operand)"
    }
}

extension CPU6502.Instruction.Operand: CustomStringConvertible {
    var description: String {
        switch self {
        case .immediate(let byte):
            return String(format: "#$%02X", byte)
        case .zeroPage(let byte):
            return String(format: "$%02X", byte)
        case .zeroPageX(let byte):
            return String(format: "$%02X,X", byte)
        case .absolute(let location):
            return String(format: "$%04X", location)
        case .absoluteX(let location):
            return String(format: "$%04X,X", location)
        case .absoluteY(let location):
            return String(format: "$%04X,Y", location)
        case .indexedIndirect(let byte):
            return String(format: "($%02X,X)", byte)
        case .indirectIndexed(let byte):
            return String(format: "($%02X),Y", byte)
        case .implied:
            return ""
        case .accumulator:
            return "A"
        case .relative(let offset):
            return "\(Int8(bitPattern: offset))"
        default:
            return "???"
        }
    }
}
