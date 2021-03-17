//
//  ID3.swift
//  p90sd-music-db
//
//  Created by Yusuke Ito on 8/12/18.
//

import Foundation
import ID3TagEditor

enum ID3ReaderError: Error {
    case id3DataReadingError
}

final class ID3Reader {
    let file: URL
    init(file: URL) {
        self.file = file
    }
    
    internal private(set) var id3Tag: ID3Tag? = nil
    
    private func parseAsWav() throws {
        let handle = try FileHandle(forReadingFrom: file)
        defer {
            handle.closeFile()
        }
        var chunk = handle.readData(ofLength: 4)
        guard chunk == "RIFF".data(using: .ascii) else {
            return
        }
        handle.seek(toFileOffset: handle.offsetInFile + 4)
        
        chunk = handle.readData(ofLength: 4)
        guard chunk == "WAVE".data(using: .ascii) else {
            return
        }
        var length: UInt32 = 0
        while true {
            chunk = handle.readData(ofLength: 4)
            if chunk.count != 4 {
                return
            }
            //print("chunk:", String.init(data: chunk, encoding: .utf8))
            let lengthData = handle.readData(ofLength: 4)
            if lengthData.count != 4 {
                return
            }
            length = UInt32(UInt32(littleEndian: lengthData.withUnsafeBytes { $0.pointee }))
            if String(data: chunk, encoding: .ascii)?.lowercased() == "id3 " {
                break // found id3 tag data
            }
            if length % 2 != 0 {
                length += 1
            }
            handle.seek(toFileOffset: handle.offsetInFile + UInt64(length))
        }
        
        if length > 0 {
            let id3Data = handle.readData(ofLength: Int(length))
            if id3Data.count != length {
                throw ID3ReaderError.id3DataReadingError
            }
            self.id3Tag = try ID3TagEditor().read(mp3: id3Data)
        }
    }
    
    func parse() throws {
        try parseAsWav()
    }
}
