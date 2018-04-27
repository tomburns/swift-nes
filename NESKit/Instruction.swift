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
        case bit = "BIT"
        case lda = "LDA"
        case nop = "NOP"
        case jsr = "JSR"
        case sei = "SEI"
        case sta = "STA"
        
        init(_ byte: UInt8) throws {
            switch byte {
            case 0x24, 0x2C:
                self = .bit
            case 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1:
                self = .lda
            case 0x20:
                self = .jsr
            case 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91:
                self = .sta
            case 0x78:
                self = .sei
            default:
                throw Error.unsupportedOpcode(byte)
            }
        }
        
        static func size(for opcode: UInt8) throws -> Int {
            switch opcode {
                //BIT:
            case 0x24:
                return 2
            case 0x2C:
                return 3
            //LDA:
            case 0xA9:
                return 2
            case 0xA5:
                return 2
            case 0xB5:
                return 2
            case 0xAD:
                return 3
            case 0xBD:
                return 3
            case 0xB9:
                return 3
            case 0xA1:
                return 2
            case 0xB1:
                return 2
            //JSR:
            case 0x20:
                return 3
            //SEI:
            case 0x78:
                return 1
            //STA:
            case 0x85:
                return 2
            case 0x95:
                return 2
            case 0x8D:
                return 3
            case 0x9D:
                return 3
            case 0x99:
                return 3
            case 0x81:
                return 2
            case 0x91:
                return 2
                
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
        
        static func name(for opcode: UInt8) throws -> String {
            switch opcode {
            case 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1:
                return "LDA"
            default:
                throw Error.unsupportedOpcode(opcode)
            }
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
                case 0xA9:
                    self = .immediate(data[1])
                case 0xA5, 0x85, 0x24:
                    self = .zeroPage(data[1])
                case 0xB5, 0x95:
                    self = .zeroPageX(data[1])
                case 0xAD, 0x8D, 0x20, 0x2C:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absolute(address)
                case 0xBD, 0x9D:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteX(address)
                case 0xB9, 0x99:
                    let address = (UInt16(data[2]) << 8) + UInt16(data[1])
                    self = .absoluteY(address)
                case 0xA1, 0x81:
                    self = .indexedIndirect(data[1])
                case 0xB1, 0x91:
                    self = .indirectIndexed(data[1])
                case 0x78:
                    self = .implied
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
        default:
            return "???"
        }
    }
}
