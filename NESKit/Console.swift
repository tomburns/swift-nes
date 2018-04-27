//
//  Console.swift
//  NESKit
//
//  Created by Tom Burns on 4/24/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

class Console {
    
    let cpu: CPU6502
    let ppu = PPU()
    
    let cartridge: Cartridge
    
    let ram = UnsafeMutableRawBufferPointer.allocate(byteCount: 2048, alignment: 1)

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
        
        let mapper = NROM128Mapper(cartridge: cartridge)
        
        let cpuMemory = CPUMemory(ram: ram, ppu: ppu, mapper: mapper)
        
        cpu = CPU6502(memory: cpuMemory)
    }
    
    
    lazy var mapper: Mapper = {
        return cartridge.mapper
    }()
    
}
