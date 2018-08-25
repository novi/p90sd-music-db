フィードバック等はIssuesまでお送りください。

# p90sd-music-db

This utiltiy allows you to generate music database file for TEAC HA-P90SD Music Player.


## Usage

1. Install Xcode 9.4.1 or later.
2. 

```sh
$ swift run -c release

P90SD media found on /Volumes/Untitled
...
database generated.
```

NOTE: Make sure that your SD card is mounted and database file `sdDatabase.edb` is on the SD card of its root.


## Supported Metadata Formats

* iTunes
* WAV with ID3 tag in id3 chunk (Supported by [XLD](http://tmkk.undo.jp/xld/index_e.html))
* `caaf/info-*` (may be used in Windows?)

### TODO

* DSF ID3 tag
* Command line options (`preferAlbumArtist`, `includeTrackNumber`). See `main.swift`.
* Docker support
