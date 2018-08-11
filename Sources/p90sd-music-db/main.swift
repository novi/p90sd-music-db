import Foundation
import EDBDatabse

let db = Database()

_ = db.appendSong(title: "demo-song1", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo1.wav")
_ = db.appendSong(title: "日本語-song2", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo2.wav")


let data = db.generateDataBase()
try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))






