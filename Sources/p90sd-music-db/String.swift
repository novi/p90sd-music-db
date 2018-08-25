//
//  String.swift
//  EDBDatabse
//
//  Created by Yusuke Ito on 8/11/18.
//

import Foundation
import EDBDatabse

fileprivate let MAX_STRING_BYTES_LENGTH = (255 - 3) / 2

fileprivate let MAX_STRING_LENGTH_UTF16 = (255 - 4) / 2

extension String {
    
    static func canAddToDatabase(path: String) -> Bool {
        return path.utf16.count < MAX_STRING_LENGTH_UTF16
    }
    
    static func songToEDBBytes(path: String, title: String, _ block: (_ pathData: UnsafePointer<UInt8>, _ pathLength: UInt8, _ titleData: UnsafePointer<UInt8>, _ titleLength: UInt8, _ encoding: p90edb_data_encoding)-> Void) {
        let truncatedTitle = String(title.utf16.prefix(MAX_STRING_LENGTH_UTF16)) ?? "TODO: truncate error"
        if let pathData = path.data(using: .ascii),
            let titleData = truncatedTitle.data(using: .ascii) {
            pathData.withUnsafeBytes { ptrPath in
                titleData.withUnsafeBytes { ptrTitle in
                    block(ptrPath, UInt8(pathData.count), ptrTitle, UInt8(titleData.count), p90edb_data_encoding_ascii)
                }
            }
        } else if let pathData = path.data(using: .utf16LittleEndian),
                let titleData = truncatedTitle.data(using: .utf16LittleEndian) {
            pathData.withUnsafeBytes { ptrPath in
                titleData.withUnsafeBytes { ptrTitle in
                    block(ptrPath, UInt8(pathData.count), ptrTitle, UInt8(titleData.count), p90edb_data_encoding_utf16)
                }
            }
        } else {
            fatalError("could not convert string to data: path:\(path),title:\(title)")
        }
    }
    
    func withEDBBytes( _ block: (_ data: UnsafePointer<UInt8>, _ length: UInt8, _ encoding: p90edb_data_encoding)-> Void ) {
        
        let truncatedTitle = String(self.utf16.prefix(MAX_STRING_LENGTH_UTF16)) ?? "TODO: truncate error"
        
        if let data = truncatedTitle.data(using: .ascii) {
            data.withUnsafeBytes { ptr in
                block(ptr, UInt8(data.count), p90edb_data_encoding_ascii)
            }
        } else if let data = self.data(using: .utf16LittleEndian) {
            data.withUnsafeBytes { ptr in
                block(ptr, UInt8(data.count), p90edb_data_encoding_utf16)
            }
        } else {
            fatalError("could not convert string to data: \(self)")
        }
    }
}
