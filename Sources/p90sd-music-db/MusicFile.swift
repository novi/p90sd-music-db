//
//  MusicFile.swift
//  p90sd-music-db
//
//  Created by Yusuke Ito on 8/12/18.
//

import Foundation
import ID3TagEditor

#if os(macOS)
import AVFoundation
#endif

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
            titleArray.append(String(format: "%01d", discNumber))
            if trackNumber != nil {
                titleArray.append("-")
            }
        }
        if let trackNumber = self.trackNumber {
            titleArray.append(String(format: "%02d", trackNumber))
        }
        titleArray.append(" " + title)
        return titleArray.joined()
    }
    
    func fetchMetadata() throws {
        #if os(macOS)
        let asset = AVAsset(url: filePath)
        //let formats = asset.availableMetadataFormats
        //print(formats)
        //for item in asset.metadata {
        //    print(item.identifier?.rawValue, item.value?.description)
        //}
        extractCafMetadata(from: asset)
        #endif
        
        try extractID3Metadata()
        
        #if os(macOS)
        extractiTunesMetadata(from: asset)
        #endif
    }
    
    func extractID3Metadata() throws {
        let id3Reader = ID3Reader(file: filePath)
        try id3Reader.parse()
        //print(id3Reader.id3Tag?.tags)
        if let id3 = id3Reader.id3Tag {
            
            self.artist = (id3.frames[.artist] as? ID3FrameWithStringContent)?.content
            self.albumArtist = (id3.frames[.albumArtist] as? ID3FrameWithStringContent)?.content
            self.title = (id3.frames[.title] as? ID3FrameWithStringContent)?.content
            self.album = (id3.frames[.album] as? ID3FrameWithStringContent)?.content
            self.genre = (id3.frames[.genre] as? ID3FrameWithStringContent)?.content
            self.trackNumber = (id3.frames[.trackPosition] as? ID3FramePartOfTotal)?.part
            if let discNumPart = (id3.frames[.discPosition] as? ID3FramePartOfTotal) {
                self.discNumber = discNumPart.part
                self.discTotal = discNumPart.total
            }
        }
    }
    
    #if os(macOS)
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
                    let tracks = Data(bytes[2...3])
                    self.trackNumber = Int(Int16(bigEndian: tracks.withUnsafeBytes { $0.pointee }))
                }
            } else if key == AVMetadataIdentifier.iTunesMetadataDiscNumber {
                if let discNumber = item.dataValue, discNumber.count == 6 {
                    let bytes = Array(discNumber)
                    let discNum = Data(bytes[2...3])
                    self.discNumber = Int(Int16(bigEndian: discNum.withUnsafeBytes { $0.pointee }))
                    let discTotal = Data(bytes[4...5])
                    self.discTotal = Int(Int16(bigEndian: discTotal.withUnsafeBytes { $0.pointee }))
                }
            }
        }
    }
    
    func extractCafMetadata(from asset: AVAsset) {
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
    #endif
    
    var description: String {
        return "title:\(title ?? "?"),artist:\(artist ?? "?"),album:\(album ?? "?"),album-artist:\(albumArtist ?? "?"),genre:\(genre ?? "?"),track:\(trackNumber ?? -1)[\(discNumber ?? -1) of \(discTotal ?? -1)],\(filePath.path)"
    }
    
    static func hasMusicFileExtension(url: URL) -> Bool {
        let validExtensions = ["wav", "m4a", "flac", "mp3", "dsf"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
}
