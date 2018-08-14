//
//  DBManipulator.swift
//  p90sd-music-db
//
//  Created by Yusuke Ito on 8/12/18.
//

import Foundation


final class DBManipulator {
    let volumePath: URL
    init(volumePath: URL) {
        self.volumePath = volumePath
    }
    
    private var files: [MusicFile] = []
    
    private func walkPath(in path: URL) {
        
        guard path.lastPathComponent.hasPrefix(".") == false else {
            // ignore files starting .
            return
        }
        
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: path.path) ) ?? []
            let paths = contents.map({ path.appendingPathComponent($0) })
            paths.forEach(walkPath)
        } else {
            // the path is file
            if MusicFile.hasMusicFileExtension(url: path) {
                let pathInDatabase = databasePathFor(filePath: path)
                if String.canAddToDatabase(path: pathInDatabase) {
                    files.append(MusicFile(filePath: path))
                } else {
                    print("file path too long", path.path)
                }
            }
        }
    }
    
    private func fetchMetadata() {
        guard files.count > 0 else {
            fatalError("no files")
        }
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "DBManipulator.fetchMetadata", attributes: .concurrent)
        for f in files {
            queue.async(group: group) {
                do {
                    try f.fetchMetadata()
                    print(f)
                } catch {
                    DispatchQueue.main.async {
                        print("could not fetch metadata on the file", f.filePath.path)
                    }
                }
            }
        }
        
        group.wait()
    }
    
    private func databasePathFor(filePath: URL) -> String {
        if #available(OSX 10.11, *) {
            let volumePathComponents = volumePath.pathComponents
            var filePathComponents = Array(filePath.pathComponents)
            for v in volumePathComponents {
                if v == filePathComponents.first {
                    filePathComponents.remove(at: 0)
                    continue
                } else {
                    break
                }
            }
            var dbPathComponents = ["C:"]
            for p in filePathComponents {
                dbPathComponents.append(p)
            }
            // convert unicode normarization to NFC
            return dbPathComponents.joined(separator: "\\").precomposedStringWithCanonicalMapping
        } else {
            fatalError("unsupported platform or macOS version")
        }
    }
    
    static func isValidVolume(volumePath: URL) -> Bool {
        return FileManager.default.fileExists(atPath: volumePath.appendingPathComponent("HA-Player.sys").path)
    }
    
    func createDatabase(preferAlbumArtist: Bool, includeTrackNumber: Bool) {
        
        guard type(of: self).isValidVolume(volumePath: volumePath) else {
            fatalError("the volume is not valid volume, \(volumePath)")
        }
        
        walkPath(in: volumePath)

        guard files.count > 0 else {
            print("no music files on this volume", volumePath)
            return
        }
        fetchMetadata()
        
        let UnknownString = "unknown"
        let db = Database()
        
        for f in files {
            let title = (includeTrackNumber ? f.titleWithTrackNumber : f.title) ?? (f.filePath.lastPathComponent)
            let artist = (preferAlbumArtist ? f.albumArtist : nil) ?? f.artist ?? UnknownString
            _ = db.appendSong(title: title,
                          artist: artist,
                          genre: f.genre ?? UnknownString,
                          album: f.album ?? UnknownString,
                          path: databasePathFor(filePath: f.filePath))
        }
        
        do {
            let data = db.generateDatabase()
            try data.write(to: volumePath.appendingPathComponent("sdDatabase.edb"))
            
            try data.write(to: URL(fileURLWithPath: "/tmp/sdDatabase.edb.debug"))
            
            print("database generated.")
            
            
        } catch {
            print("database write error", error)
        }
    }
    
}
