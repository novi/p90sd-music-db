import Foundation
import EDBDatabse

let db = p90edb_create()!

"demo-artist".withEDBBytes { (data, len, encoding) in
    p90edb_append_artist(db, 1, data, len, encoding)
}

"demo-genre".withEDBBytes { (data, len, encoding) in
    p90edb_append_genre(db, 1, data, len, encoding)
}

"demo-album".withEDBBytes { (data, len, encoding) in
    p90edb_append_album(db, 1, 1, 1, data, len, encoding)
}

String.songToEDBBytes(path: "C:\\music\\demo1.wav", title: "demo-song1", { (pathData, pathLength, titleData, titleLength, encoding) in
    p90edb_append_song(db, 1, 1, 1, 1, pathData, pathLength, titleData, titleLength, encoding)
})

String.songToEDBBytes(path: "C:\\music\\demo2.wav", title: "日本語-song2", { (pathData, pathLength, titleData, titleLength, encoding) in
    p90edb_append_song(db, 1, 1, 1, 2, pathData, pathLength, titleData, titleLength, encoding)
})

p90edb_finalize(db)

let data = Data(bytes: p90edb_get_file_buffer(db), count: Int(p90edb_get_file_size(db)))

try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))








