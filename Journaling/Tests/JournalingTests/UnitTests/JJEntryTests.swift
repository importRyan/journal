//  © 2021 Ryan Ferrell. github.com/importRyan

import XCTest
@testable import Journaling

final class JJEntryTests: XCTestCase {

    func testEditsTitleSeparately() {
        var sut = MockEntry.original
        let originalTitle = sut.title
        let originalContent = sut.content
        let updatedTitle = "Updated"

        sut.update(title: updatedTitle, content: nil)

        XCTAssertNotEqual(sut.title, originalTitle)
        XCTAssertEqual(sut.title, updatedTitle)
        XCTAssertEqual(sut.content, originalContent)
    }

    func testEditsContentSeparately() {
        var sut = MockEntry.original
        let originalTitle = sut.title
        let originalContent = sut.content
        let updatedContent: String = "Updated"

        sut.update(title: nil, content: updatedContent)

        XCTAssertEqual(sut.title, originalTitle)
        XCTAssertNotEqual(sut.content, originalContent)
        XCTAssertEqual(sut.content, updatedContent)
    }

    func testEditsTitleAndContentSimultaneously() {
        var sut = MockEntry.original
        let updatedTitle = "Updated Title"
        let updatedContent: String = "Updated Content"

        sut.update(title: updatedTitle, content: updatedContent)

        XCTAssertEqual(sut.title, updatedTitle)
        XCTAssertEqual(sut.content, updatedContent)
    }

    func testEditsWillRefreshEditedDate() {
        let oldDate = Date(timeIntervalSince1970: 0)
        var sut = JJEntry(id: .init(), title: "Original", content: "", edited: oldDate, created: oldDate)
        sut.update(title: "Updated", content: nil)
        XCTAssertGreaterThan(sut.dateEdited, sut.dateCreated)
    }
}
