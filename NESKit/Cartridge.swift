//
//  Cartridge.swift
//  NESKit
//
//  Created b y Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

public class Cartridge: Codable {
    static let validPreamble = Data(bytes: [78, 69, 83, 26]) // "NES^Z"

    fileprivate(set) var ram: Data
    fileprivate(set) var prg: Data
    fileprivate(set) var chr: Data

    let mapperValue: Int

    var mapper: Mapper {
        guard mapperValue == 0 else {
            fatalError("we only support NROM right now")
        }

        return NROM128Mapper(cartridge: self)
    }

    public init(data: Data) throws {
        guard data[0...3] == Cartridge.validPreamble else {
            throw CartridgeError.invalidPreamble
        }

        let control1 = data[6]
        let control2 = data[7]

        mapperValue = Int((control1 >> 4) | ((control2 >> 4) << 4))

        let romByteCount = 16 * 1024 * Int(data[4])
        let vromByteCount = 8 * 1024 * Int(data[5])

        let gameData = data.advanced(by: 16)

        prg = gameData.prefix(romByteCount)
        chr = gameData.suffix(vromByteCount)

        ram = Data.init(count: 4 * 1024)

        assert(chr.count == vromByteCount)
    }
}

enum CartridgeError: Error {
    case invalidPreamble
}

protocol Mapper: Memory {
    func read(_ address: UInt16) -> UInt8
    func read16(_ address: UInt16) -> UInt16
    func read16Bug(_ address: UInt16) -> UInt16
    func write(_ value: UInt8, to address: UInt16)
    func step()
}

struct NROM128Mapper: Mapper {

    let cartridge: Cartridge

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
    }

    func read(_ address: UInt16) -> UInt8 {
        switch address {
        case 0x0000..<0x2000:
            return cartridge.chr[Int(address)]
        case 0x6000..<0x8000:
            return cartridge.ram[Int(address-0x6000)]
        case 0x8000..<0xC000:
//            return cartridge.prg[Int(address-0x8000)]
            break
        case 0xC000...0xFFFF:
//            return cartridge.prg[Int(address-0xC000)]
            break
        default:
            fatalError("unsupported NROM-256 read at \(address)")
        }

        let prgAddress = Int(address) % 0x4000

        let value = cartridge.prg[prgAddress]

//        print(String(format: "Mapper read %02X from address %04X", value, address))

        return value
    }

    func write(_ value: UInt8, to address: UInt16) {
        switch address {
        case 0x0000..<0x2000:
            cartridge.chr[Int(address)] = value
        case 0x6000..<0x8000:
            cartridge.ram[Int(address-0x6000)] = value
        case 0x8000..<0xC000:
            cartridge.prg[Int(address-0x8000)] = value
        case 0xC000...0xFFFF:
            cartridge.prg[Int(address-0xC000)] = value
        default:
            fatalError("unsupported NROM-256 read at \(address)")
        }
    }

    func step() {
        assertionFailure("NROM doesn't support stepping")
    }
}
