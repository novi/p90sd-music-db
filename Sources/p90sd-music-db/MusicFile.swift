//
//  MusicFile.swift
//  p90sd-music-db
//
//  Created by Yusuke Ito on 8/12/18.
//

import Foundation
import AVFoundation

final class MusicFile: CustomStringConvertible {
    let filePath: URL
    init(filePath: URL) {
        self.filePath = filePath
    }
    
    var title: String? = nil
    var album: String? = nil
    var albumArtist: String? = nil
    var artist: String? = nil
    var genre: String? = nil
    var discNumber: Int? = nil
    var discTotal: Int? = nil
    var trackNumber: Int? = nil
    
    var titleWithTrackNumber: String? {
        guard let title = self.title else {
            return nil
        }
        var titleArray: [String] = []
        if let discTotal = self.discTotal, let discNumber = self.discNumber, discTotal >= 2 {
            titleArray.append(String(format: "%02d", discNumber))
        }
        if let trackNumber = self.trackNumber {
            titleArray.append(String(format: "%02d", trackNumber))
        }
        titleArray.append(title)
        return titleArray.joined(separator: " ")
    }
    
    func fetchMetadata() throws {
        let asset = AVAsset(url: filePath)
        //let formats = asset.availableMetadataFormats
        //print(formats)
        //for item in asset.metadata {
        //    print(item.identifier?.rawValue, item.value?.description)
        //}
        extractiCafMetadata(from: asset)
        extractiID3Metadata()
        extractiTunesMetadata(from: asset)
    }
    
    func extractiID3Metadata() {
        do {
            let id3Reader = ID3Reader(file: filePath)
            try id3Reader.parse()
            //print(id3Reader.id3Tag?.tags)
            if let id3 = id3Reader.id3Tag {
                self.artist = id3.artist
                self.albumArtist = id3.albumArtist
                self.title = id3.title
                self.album = id3.album
                self.genre = id3.genre?.description
                self.trackNumber = id3.trackPosition?.position
                if let discNumString = id3.tags["TPOS"] {
                    let parts = discNumString.split(separator: "/").map(String.init)
                    if parts.count == 1 {
                        self.discNumber = Int(parts[0])
                    } else if parts.count == 2 {
                        self.discNumber = Int(parts[0])
                        self.discTotal = Int(parts[1])
                    }
                }
            }
        } catch {
            print("id3 reading error on \(filePath.path)")
        }
    }
    
    func extractiTunesMetadata(from asset: AVAsset) {
        let items = AVMetadataItem.metadataItems(from: asset.metadata, withKey: nil, keySpace: .iTunes)
        for item in items {
            guard let key = item.identifier else {
                continue
            }
            if key == AVMetadataIdentifier.iTunesMetadataArtist {
                if let artist = item.stringValue {
                    self.artist = artist
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataAlbum {
                if let album = item.stringValue {
                    self.album = album
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataSongName {
                if let title = item.stringValue {
                    self.title = title
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataPredefinedGenre {
                if let genre = item.stringValue {
                    self.genre = genre
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataUserGenre {
                if let genre = item.stringValue {
                    self.genre = genre
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataAlbumArtist {
                if let albumArtist = item.stringValue {
                    self.albumArtist = albumArtist
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataTrackNumber {
                if let trackNumber = item.dataValue, trackNumber.count == 8 {
                    let bytes = Array(trackNumber)
                    let tracks = Data(bytes: bytes[2...3])
                    self.trackNumber = Int(Int16(bigEndian: tracks.withUnsafeBytes { $0.pointee }))
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataDiscNumber {
                if let discNumber = item.dataValue, discNumber.count == 6 {
                    let bytes = Array(discNumber)
                    let discNum = Data(bytes: bytes[2...3])
                    self.discNumber = Int(Int16(bigEndian: discNum.withUnsafeBytes { $0.pointee }))
                    let discTotal = Data(bytes: bytes[4...5])
                    self.discTotal = Int(Int16(bigEndian: discTotal.withUnsafeBytes { $0.pointee }))
                }
            }
        }
    }
    
    func extractiCafMetadata(from asset: AVAsset) {
        let items = asset.metadata
        for item in items {
            guard let key = item.identifier else {
                continue
            }
            if key == AVMetadataIdentifier("caaf/info-artist") {
                if let artist = item.stringValue {
                    self.artist = artist
                }
            } else if key == AVMetadataIdentifier("caaf/info-title") {
                if let title = item.stringValue {
                    self.title = title
                }
            } else if key == AVMetadataIdentifier("caaf/info-genre") {
                if let genre = item.stringValue {
                    self.genre = genre
                }
            }
        }
    }
    
    var description: String {
        return "title:\(title as Any),artist:\(artist as Any),album:\(album as Any),album-artist:\(albumArtist as Any),genre:\(genre as Any),track:\(trackNumber as Any)[\(discNumber as Any) of \(discTotal as Any)],\(filePath.path)"
    }
    
    static func hasMusicFileExtension(url: URL) -> Bool {
        let extensions = ["wav", "m4a", "flac", "mp3", "dsf"]
        return extensions.contains(url.pathExtension.lowercased())
    }
}
