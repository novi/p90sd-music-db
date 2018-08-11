import Foundation
import EDBDatabse

extension String {
    
    func withBytes( _ block: (_ data: UnsafePointer<UInt8>, _ len: UInt8, _ encoding: p90edb_data_encoding)-> Void ) {
        
        // TODO: truncate string
        if let data = self.data(using: .ascii) {
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

let db = p90edb_create()!

"demo-artist".withBytes { (data, len, encoding) in
    p90edb_append_artist(db, 1, data, len, encoding)
}

"demo-genre".withBytes { (data, len, encoding) in
    p90edb_append_genre(db, 1, data, len, encoding)
}

"demo-album".withBytes { (data, len, encoding) in
    p90edb_append_album(db, 1, 1, 1, data, len, encoding)
}

"demo-song1".withBytes { (data_title, len_title, encoding_title) in
    "C:\\music\\demo1.wav".withBytes { (data_path, len_path, encoding_path) in
        p90edb_append_song(db, 1, 1, 1, 1, data_path, len_path, data_title, len_title, encoding_title)
    }
}

"日本語-song2".withBytes { (data_title, len_title, encoding_title) in
    let pathData = "C:\\music\\demo2.wav".data(using: .utf16LittleEndian)!
    pathData.withUnsafeBytes { ptr in
        p90edb_append_song(db, 1, 1, 1, 2, ptr, UInt8(pathData.count), data_title, len_title, encoding_title)
    }
}


p90edb_finalize(db)

let data = Data(bytes: p90edb_get_file_buffer(db), count: Int(p90edb_get_file_size(db)))

try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))








