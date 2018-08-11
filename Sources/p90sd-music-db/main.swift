import Foundation
import EDBDatabse

let db = Database()

_ = db.appendSong(title: "demo-song1", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo1.wav")
_ = db.appendSong(title: "日本語-song2", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo2.wav")

_ = db.appendSong(title: "demo-song2", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo2.wav")

_ = db.appendSong(title: "demo-song3", artist: "demo-artist", genre: "demo-genre", album: "demo-album2", path: "C:\\music\\demo1.wav")

_ = db.appendSong(title: "demo-song4", artist: "demo-artist-2", genre: "demo-genre", album: "demo-album2", path: "C:\\music\\demo1.wav")


let data = db.generateDatabase()
try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))






