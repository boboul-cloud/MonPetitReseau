//
//  URLCodec.swift
//  MonPetitReseau
//
//  Compact URL codec : JSON -> zlib (raw deflate) -> base64url
//

import Foundation
import Compression

enum URLCodec {

    static func encode(_ wire: FamilyWire) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let json = try? encoder.encode(wire) else { return nil }
        guard let compressed = zlibCompress(json) else { return nil }
        return base64urlEncode(compressed)
    }

    static func decode(_ token: String) -> FamilyWire? {
        guard let compressed = base64urlDecode(token) else { return nil }
        guard let json = zlibDecompress(compressed) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(FamilyWire.self, from: json)
    }

    // MARK: - base64url

    static func base64urlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func base64urlDecode(_ s: String) -> Data? {
        var str = s.replacingOccurrences(of: "-", with: "+")
                   .replacingOccurrences(of: "_", with: "/")
        let pad = (4 - str.count % 4) % 4
        str += String(repeating: "=", count: pad)
        return Data(base64Encoded: str)
    }

    // MARK: - zlib raw deflate (matches pako.deflateRaw / inflateRaw)

    static func zlibCompress(_ data: Data) -> Data? {
        let dstCap = data.count + 1024 + data.count / 100
        let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCap)
        defer { dst.deallocate() }
        let written = data.withUnsafeBytes { src -> Int in
            guard let base = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_encode_buffer(dst, dstCap, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        return Data(bytes: dst, count: written)
    }

    static func zlibDecompress(_ data: Data) -> Data? {
        // Try increasing buffer sizes
        for multiplier in [8, 32, 128, 512] {
            let dstCap = max(data.count * multiplier, 4096)
            let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCap)
            defer { dst.deallocate() }
            let written = data.withUnsafeBytes { src -> Int in
                guard let base = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                return compression_decode_buffer(dst, dstCap, base, data.count, nil, COMPRESSION_ZLIB)
            }
            if written > 0 && written < dstCap {
                return Data(bytes: dst, count: written)
            }
        }
        return nil
    }
}
