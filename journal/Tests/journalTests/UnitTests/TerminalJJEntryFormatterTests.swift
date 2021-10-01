//  © 2021 Ryan Ferrell. github.com/importRyan

import XCTest
@testable import journal
@testable import Journaling

final class TerminalJJEntryFormatterTests: XCTestCase {

    func test_ID_IsPlainUUIDStringFormatting() {
        let cases: [IDTest] = TestCases.uuidCases
        let sut: JJEntryIDFormatting = TerminalJJEntryFormatter().id
        cases.enumerated().forEach { (index, test) in
            XCTAssertEqual(sut.format(test.test), test.exp, String(index))
        }
    }

    func test_Title_ReplacesEmptyStringWithUntitled() {
        let cases: [TitleTest] = [
            .init(test: "", exp: "[Untitled]"),
        ]
        let sut: JJTitleFormatting = TerminalJJEntryFormatter().title
        cases.enumerated().forEach { (index, test) in
            XCTAssertEqual(sut.format(test.test), test.exp, String(index))
        }
    }

    func test_Title_DoesNotChangeText() {
        let cases: [TitleTest] = [
            .init(test: " ", exp: " "),
            .init(test: "🪂", exp: "🪂"),
            .init(test: "$%^$%", exp: "$%^$%"),
            .init(test: " NoChanges ", exp: " NoChanges "),
            .init(test: "♲⚛︎☁︎", exp: "♲⚛︎☁︎"),
            .init(test: "\n", exp: "\n")
        ]
        let sut: JJTitleFormatting = TerminalJJEntryFormatter().title
        cases.enumerated().forEach { (index, test) in
            XCTAssertEqual(sut.format(test.test), test.exp, String(index))
        }
    }

    func test_Date_UsesShortFormatting() {
        let cases: [DateTest] = [
            .init(test: Date(timeIntervalSince1970: 4_219_222), exp: "2/18/70, 12:00 PM"),
            .init(test: Date(timeIntervalSince1970: 5_222_222), exp: "3/2/70, 2:37 AM"),
            .init(test: Date(timeIntervalSince1970: 6_222_222), exp: "3/13/70, 4:23 PM"),
        ]
        let sut: JJDateFormatting = TerminalJJEntryFormatter().date
        cases.enumerated().forEach { (index, test) in
            XCTAssertEqual(sut.format(test.test), test.exp, String(index))
        }
    }
}

fileprivate struct DateTest {
    let test: Date
    let exp: String
}

fileprivate struct IDTest {
    let test: UUID
    let exp: String
}

fileprivate struct TitleTest {
    let test: String
    let exp: String
}

fileprivate enum TestCases {

    static let ids: [UUID] = idStrings.compactMap(UUID.init(uuidString:))

    static let idStrings: [String] = [
        "24BDBC0A-FA98-497C-A15F-81099A782C11",
        "8D47DEBB-F328-45CB-B4B5-678BB52D5C2F",
        "F3B80477-BC1B-43A2-BFAA-50A4AFD40698",
        "33CE0404-31C3-4D8E-AC03-41709A6F39A4"
    ]

    static let uuidCases = zip(ids, idStrings).map(IDTest.init)
}
