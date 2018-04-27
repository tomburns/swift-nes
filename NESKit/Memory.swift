//
//  Memory.swift
//  NESKit
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

protocol Memory {
    func read(_ address: UInt16) -> UInt8
    func read16(_ address: UInt16) -> UInt16
    func write(_ value: UInt8, to address: UInt16)
}

extension Memory {
    func read16(_ address: UInt16) -> UInt16 {
        let high = read(address+1)
        let low = read(address)
        
        return (UInt16(high) << 8) + UInt16(low)
    }
}

class CPUMemory: Memory {
    private let ram: UnsafeMutableRawBufferPointer
    
    private let mapper: Mapper
    
    init(ram: UnsafeMutableRawBufferPointer, mapper: Mapper) {
        self.mapper = mapper
        self.ram = ram
    }
    
    func read(_ address: UInt16) -> UInt8 {
        switch address {
        case 0x0000..<0x2000:
            return ram[Int(address % 0x0800)]
        case 0x2000..<0x4000:
            print("should be reading from PPU register here")
            return 0
        case 0x6000...0xFFFF:
            return mapper.read(address)
        default:
            fatalError(String(format: "illegal/unsupported cpu memory read: 0x%04X", address))
        }
    }
    
    func write(_ value: UInt8, to address: UInt16) {
        switch address {
        case 0x0000..<0x2000:
            ram[Int(address % 0x0800)] = value
        case 0x2000..<0x4000:
            print("should be writing to PPU register here")
        case 0x4000..<0x4014:
            print("should be writing to APU register here")
        case 0x4014:
            print("should be writing to PPU register here")
        case 0x4015:
            print("should be writing to APU register here")
        case 0x4016:
            print("should be writing to Controllers here")
        case 0x4017:
            print("should be writing to APU here")
        case 0x4018..<0x6000:
            print("I/O Registers!")
        case 0x6000...0xFFFF:
            mapper.write(value, to: address)
        default:
            fatalError(String(format: "illegal/unsupported cpu memory write to 0x%04X", address))
        }
    }
}

extension UnsafeMutableRawBufferPointer: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        var bytes: [UInt8] = []
        
        while let next = try? container.decode(UInt8.self) {
            bytes.append(next)
        }
        
        self = .allocate(byteCount: bytes.count, alignment: 1)
        
        self.copyBytes(from: bytes)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(self)
    }
}
