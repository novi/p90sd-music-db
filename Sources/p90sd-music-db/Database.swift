//
//  Database.swift
//  p90sd-music-db
//
//  Created by Yusuke Ito on 8/12/18.
//

import Foundation
import EDBDatabse

fileprivate protocol EDBWritable {
    func write(to: UnsafeMutablePointer<p90edb_database>)
}

fileprivate struct Artist: EDBWritable {
    let id: Int
    let name: String
    
    func write(to: UnsafeMutablePointer<p90edb_database>) {
        self.name.withEDBBytes { (data, len, encoding) in
            p90edb_append_artist(to, UInt32(id), data, len, encoding)
        }
    }
}

fileprivate struct Genre: EDBWritable {
    let id: Int
    let name: String
    
    func write(to: UnsafeMutablePointer<p90edb_database>) {
        self.name.withEDBBytes { (data, len, encoding) in
            p90edb_append_genre(to, UInt32(id), data, len, encoding)
        }
    }
}

fileprivate struct Album: EDBWritable {
    
    struct Key: Equatable, Hashable {
        let artistID: Int
        let albumName: String
    }
    
    let id: Int
    let artistID: Int
    let genreID: Int
    let name: String
    
    func write(to: UnsafeMutablePointer<p90edb_database>) {
        self.name.withEDBBytes { (data, len, encoding) in
            p90edb_append_album(to, UInt32(artistID), UInt32(genreID), UInt32(id), data, len, encoding)
        }
    }
}

fileprivate struct Song: EDBWritable {
    let id: Int
    let artistID: Int
    let genreID: Int
    let albumID: Int
    let title: String
    let path: String
    
    func write(to: UnsafeMutablePointer<p90edb_database>) {
        String.songToEDBBytes(path: path, title: title, { (pathData, pathLength, titleData, titleLength, encoding) in
            p90edb_append_song(to, UInt32(artistID), UInt32(genreID), UInt32(albumID), UInt32(id), pathData, pathLength, titleData, titleLength, encoding)
        })
    }
}


final class Database {
    
    private let db: UnsafeMutablePointer<p90edb_database>
    init() {
        db = p90edb_create()!
    }
    
    private var records: [EDBWritable] = []
    
    private var songs: [Song] = []
    private var latestSongID: Int = 0
    
    private var artist: [String: Artist] = [:]
    private var latestArtistID: Int = 0
    
    private func getArtist(name: String) -> Artist {
        if let artist = self.artist[name] {
            return artist
        }
        let artist = Artist(id: latestArtistID + 1, name: name)
        self.latestArtistID = artist.id
        self.artist[name] = artist
        self.records.append(artist)
        return artist
    }
    
    deinit {
        //p90edb_destroy(&db)
    }
    
    private var genre: [String: Genre] = [:]
    private var latestGenreID: Int = 0
    
    private func getGenre(name: String) -> Genre {
        if let genre = self.genre[name] {
            return genre
        }
        let genre = Genre(id: latestGenreID + 1, name: name)
        self.latestGenreID = genre.id
        self.genre[name] = genre
        self.records.append(genre)
        return genre
    }
    
    private var album: [Album.Key: Album] = [:]
    private var latestAlbumID: Int = 0
    
    private func getAlbum(name: String, artist: Artist, genre: Genre) -> Album {
        let key = Album.Key(artistID: artist.id, albumName: name)
        
        if let album = self.album[key] {
            return album
        }
        let album = Album(id: latestAlbumID + 1, artistID: artist.id, genreID: genre.id, name: name)
        self.latestAlbumID = album.id
        self.album[key] = album
        self.records.append(album)
        return album
    }
    
    func appendSong(title: String, artist: String, genre: String, album: String, path: String) -> Bool {
        
        #if DEBUG || Xcode
        print(path, path.utf16.count)
        #endif
        guard String.canAddToDatabase(path: path) else {
            print("could not add to the database. path:\(path)")
            return false
        }
        
        let artist = getArtist(name: artist)
        let genre = getGenre(name: genre)
        let album = getAlbum(name: album, artist: artist, genre: genre)
        
        let song = Song(id: latestSongID + 1,
                        artistID: artist.id, genreID: genre.id, albumID: album.id, title: title, path: path)
        songs.append(song)
        self.latestSongID = song.id
        self.records.append(song)
        return true
    }
    
    func generateDatabase() -> Data {
        for record in records {
            record.write(to: db)
        }
        p90edb_finalize(db)
        return Data(bytes: p90edb_get_file_buffer(db), count: Int(p90edb_get_file_size(db)))
    }
}
