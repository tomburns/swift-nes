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
        case lda = "LDA"
        case ldx = "LDX"
        case nop = "NOP"
        case jsr = "JSR"
        case sei = "SEI"
        case sta = "STA"
        case pha = "PHA"
        case jmp = "JMP"
        case brk = "BRK"
        case php = "PHP"
        case rol = "ROL"
        case ror = "ROR"
        case inc = "INC"
        
        //Branch Instructions
        case bpl = "BPL"
        case beq = "BEQ"
        case bne = "BNE"
        
        //Register Instructions
        case tax = "TAX"
        case txa = "TXA"
        case dex = "DEX"
        case inx = "INX"
        case tay = "TAY"
        case tya = "TYA"
        case dey = "DEY"
        case iny = "INY"
        
        init(_ byte: UInt8) throws {
            switch byte {
            case 0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71:
                self = .adc
            case 0x00:
                self = .brk
            case 0x08:
                self = .php
            case 0x10:
                self = .bpl
            case 0xF0:
                self = .beq
            case 0xD0:
                self = .bne
            case 0x24, 0x2C:
                self = .bit
            case 0xE6, 0xF6, 0xEE, 0xFE:
                self = .inc
            case 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1:
                self = .lda
            case 0x20:
                self = .jsr
            case 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91:
                self = .sta
            case 0x78:
                self = .sei
            case 0x48:
                self = .pha
            case 0xA2, 0xA6, 0xB6, 0xAE, 0xBE:
                self = .ldx
            case 0xAA:
                self = .tax
            case 0x8A:
                self = .txa
            case 0xCA:
                self = .dex
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
            default:
                throw Error.unsupportedOpcode(byte)
            }
        }
        
        static func size(for opcode: UInt8) throws -> Int {
            switch opcode {
            case 0x6A, 0x2A, 0x00, 0x78, 0x9A, 0xBA, 0x48, 0x68, 0x08, 0x28, 0xAA, 0x8A, 0xCA, 0xE8, 0xA8, 0x98, 0x88, 0xC8:
                return 1
            case 0xE6, 0xF6, 0x66, 0x76, 0x26, 0x36, 0x10, 0xF0, 0x24, 0x81, 0x91, 0x85, 0x95, 0xA1, 0xB1, 0xA9, 0xA5, 0xB5, 0xA2, 0xA6, 0xB6, 0xD0:
                return 2
            case 0x6E, 0x7E, 0x2E, 0x3E, 0x2C, 0xAD, 0xBD, 0xB9, 0x20, 0x8D, 0x9D, 0x99, 0xAE, 0xBE, 0x4C, 0x6C, 0xEE, 0xFE:
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
        
        private let data: Data
        
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
                case 0x69, 0xA9, 0xA2:
                    self = .immediate(data[1])
                case 0xE6, 0x65, 0x26, 0xA5, 0x85, 0x24, 0xA6, 0x66:
                    self = .zeroPage(data[1])
                case 0xF6, 0x75, 0x36, 0xB5, 0x95, 0x76:
                    self = .zeroPageX(data[1])
                case 0xB6:
                    self = .zeroPageY(data[1])
                case 0xEE, 0x6D, 0x2E, 0xAD, 0x8D, 0x20, 0x2C, 0xAE, 0x4C, 0x6E:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absolute(address)
                case 0xFE, 0x7D, 0x3E, 0xBD, 0x9D, 0x7E:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteX(address)
                case 0x79, 0xB9, 0x99, 0xBE:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteY(address)
                case 0x6C:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .indirect(address)
                case 0x61, 0xA1, 0x81:
                    self = .indexedIndirect(data[1])
                case 0x71, 0xB1, 0x91:
                    self = .indirectIndexed(data[1])
                case 0x00, 0x78, 0x9A, 0xBA, 0x48, 0x68, 0x08, 0x28, 0xAA, 0x8A, 0xCA, 0xE8, 0xA8, 0x98, 0x88, 0xC8, 0xD0:
                    self = .implied
                case 0xF0, 0x10:
                    self = .relative(data[1])
                case 0x2A, 0x6A:
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
