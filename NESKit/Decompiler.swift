//
//  Decompiler.swift
//  NESKit
//
//  Created by Tom Burns on 4/25/18.
//  Copyright © 2018 Claptrap. All rights reserved.
//

import Foundation

extension CPU6502 {
    struct Decompiler {
        let onNext: (String) -> Void

        init(_ onNext: @escaping (String) -> Void) {
            self.onNext = onNext
        }

        func parse(_ data: Data) throws -> String {

            var output = ""

            var remainder = data

            while let opcodeByte = remainder.first {
                guard let size = try? Opcode.size(for: opcodeByte) else {
                    output.append("???\n")
                    break
                }

                let instruction = try Instruction(remainder[0..<size])

                output.append("\(instruction.description)\n")

                remainder = Data(remainder.dropFirst(size))
            }

            return output
        }
    }
}

extension CPU6502.Instruction: CustomDebugStringConvertible {
    var debugDescription: String {
        return self.opcode.rawValue
    }
}
