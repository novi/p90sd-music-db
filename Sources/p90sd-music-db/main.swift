import Foundation
import EDBDatabse

let db = p90edb_create()!

let demo = "demo"
let demoData = demo.data(using: .ascii)!
demoData.withUnsafeBytes { ptr in
    // TODO: truncate title
    p90edb_append_artist(db, 1, ptr, UInt8(demoData.count), p90edb_data_encoding_ascii)
}

p90edb_finalize(db)

let data = Data(bytes: p90edb_get_file_buffer(db), count: Int(p90edb_get_file_size(db)))

try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))








