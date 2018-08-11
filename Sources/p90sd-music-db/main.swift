import Foundation
import EDBDatabse

let db = p90edb_create()!;

p90edb_finalize(db);

let data = Data(bytes: p90edb_get_file_buffer(db), count: Int(p90edb_get_file_size(db)))

try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))







