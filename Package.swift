// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2018 Yusuke Ito
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import PackageDescription

let package = Package(
    name: "p90sd-music-db",
    dependencies: [
        .package(url: "https://github.com/chicio/ID3TagEditor.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "p90sd-music-db",
            dependencies: ["EDBDatabse", "ID3TagEditor"]),
        .target(
            name: "EDBDatabse"),
        .testTarget(
            name: "p90sd-music-dbTests",
            dependencies: ["p90sd-music-db"]),
    ]
)
