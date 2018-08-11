import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(p90sd_music_dbTests.allTests),
    ]
}
#endif