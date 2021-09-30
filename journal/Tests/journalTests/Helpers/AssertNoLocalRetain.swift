//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import XCTest

extension XCTestCase {

    func assertNoLocalRetainCycle(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Not deallocated.", file: file, line: line)
        }
    }
}
