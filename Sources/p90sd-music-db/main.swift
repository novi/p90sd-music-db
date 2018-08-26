import Foundation
import EDBDatabse
import CoreFoundation

DispatchQueue.main.async {
    for item in try! FileManager.default.contentsOfDirectory(atPath: "/Volumes") {
        let volumePath = URL(fileURLWithPath: "/Volumes").appendingPathComponent(item)
        if DBManipulator.isValidVolume(volumePath: volumePath) {
            print("P90SD media found on \(volumePath.path)")
            let manipulator = DBManipulator(volumePath: volumePath)
            manipulator.createDatabase(preferAlbumArtist: true, includeTrackNumber: true)
        }
    }
    DispatchQueue.main.async {
        CFRunLoopStop(CFRunLoopGetMain())
    }
}

CFRunLoopRun()




/*
let db = Database()

_ = db.appendSong(title: "demo-song1", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo1.wav")
_ = db.appendSong(title: "あい-song2", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo2.wav")

_ = db.appendSong(title: "demo-song2", artist: "demo-artist", genre: "demo-genre", album: "demo-album", path: "C:\\music\\demo2.wav")

_ = db.appendSong(title: "demo-song3", artist: "demo-artist", genre: "demo-genre", album: "demo-album2", path: "C:\\music\\demo1.wav")

_ = db.appendSong(title: "demo-song4", artist: "demo-artist-2", genre: "demo-genre", album: "demo-album2", path: "C:\\music\\demo1.wav")


let data = db.generateDatabase()
try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))

*/








