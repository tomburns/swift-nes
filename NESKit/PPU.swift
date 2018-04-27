//
//  PPU.swift
//  NESKit
//
//  Created by Tom Burns on 4/27/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

class PPU {
    
    private var paletteData = Data(count: 32)
    private var nameTableData = Data(count: 2048)

    private var oamData = Data(count: 256)
    private var oamAddress: UInt8 = 0
    
    private var register: UInt8 = 0
    
    private var spriteOverflowFlag: UInt8 = 0
    private var spriteZeroHitFlag: UInt8 = 0

    private var write: Bool = false

    
    var nmiOccurred = false
    
    func readRegister(_ address: UInt16) -> UInt8 {
        switch address {
        case 0x2002:
            return readStatus()
        case 0x2004:
            return readOAMData()
        case 0x2007:
            return readData()
        default:
            return 0
        }
    }
    
    func readStatus() -> UInt8 {
        var status = register & 0x1F
        status |= spriteOverflowFlag << 5
        status |= spriteZeroHitFlag << 6
        
        if nmiOccurred {
            status |= 1 << 7
        }
        
        nmiOccurred = false
        nmiDidChange()
        
        write = false
        
        return status
    }
    
    func readOAMData() -> UInt8 {
        return oamData[Int(oamAddress)]
    }
    
    func readData() -> UInt8 {
        print("Haven't implemented PPU Data read!")
        return 0
    }
    
    private func nmiDidChange() {
        print("need to handle NMI change")
    }
}
