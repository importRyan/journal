//  Â© 2021 Ryan Ferrell. github.com/importRyan

import XCTest

class FittedStringTests: XCTestCase {

    func testDoesNotChangeStringsOfExactLength() {
        let cases: [TestCase] = [
            .init(test: "Plain",   exp: "Plain",   length: 5),
            .init(test: "Emðªji",  exp: "Emðªji",  length: 5),
            .init(test: "ðððââ",  exp: "ðððââ",   length: 5),
        ]

        cases.enumerated().forEach { (index, test) in
            let result = test.test.fitted(to: test.length, withPad: " ", truncationMarker: .none)
            XCTAssertEqual(test.exp, result, String(index))
        }
    }

    func testExpandsStrings() {
        let cases: [TestCase] = [
            .init(test: "Plain",   exp: "Plain  ",   length: 7),
            .init(test: "Emðªji",  exp: "Emðªji  ",  length: 7),
            .init(test: "ðððââ",  exp: "ðððââ  ",   length: 7),
        ]

        cases.enumerated().forEach { (index, test) in
            let result = test.test.fitted(to: test.length, withPad: " ", truncationMarker: .none)
            XCTAssertEqual(test.exp, result, String(index))
        }
    }

    func testTrimsStrings() {
        let cases: [TestCase] = [
            .init(test: "Plain",   exp: "Pla",   length: 3),
            .init(test: "Emðªji",  exp: "Emðª",  length: 3),
            .init(test: "ðððââ",  exp: "ððð",   length: 3),
        ]

        cases.enumerated().forEach { (index, test) in
            let result = test.test.fitted(to: test.length, withPad: " ", truncationMarker: .none)
            XCTAssertEqual(test.exp, result, String(index))
        }
    }

    /// Foundation's method String.padding(toLength:::) uses (UTF-16 code units, rather than Characters.)[https://forums.swift.org/t/string-padding-method-is-broken/14417].
    func testHandlesSwiftPaddingToLengthFailures() {
        let cases: [TestCase] = [
            .init(test: "Ð°Ð°ÌÐ°",  exp: "Ð°Ð°ÌÐ° ",  length: 4),
            .init(test: "Ð°Ð°ÌÐ°",  exp: "Ð°Ð°ÌÐ°",   length: 3),
            .init(test: "Ð°Ð°ÌÐ°",  exp: "Ð°Ð°Ì",    length: 2),
            .init(test: "Ð°Ð°ÌÐ°",  exp: "Ð°",     length: 1),
            .init(test: "a\u{e1}a",    exp: "Ð°Ð°ÌÐ°",     length: 3),
            .init(test: "aa\u{301}a",  exp: "Ð°Ð°ÌÐ° ",    length: 4),
            .init(test: "ð",  exp: "ð",     length: 1),
            .init(test: "ð",  exp: "ð ",    length: 2),
            .init(test: "ð",  exp: "ð  ",   length: 3),
        ]

        cases.enumerated().forEach { (index, test) in
            let result = test.test.fitted(to: test.length, withPad: " ", truncationMarker: .none)
            zip(Array(test.test), Array(result)).forEach { (exp, res) in
                XCTAssertEqual(exp, res, "\(exp) != \(res) in test case \(index)")
            }
        }
    }

    func testOutOfBoundsDoesNotCrash() {
        let strings = ["Plain", "Emðªji", "ðððââ"]
        let lowerLimits = [Int.min, -1, 0]

        for limit in lowerLimits {
            for str in strings {
                let result = str.fitted(to: limit, withPad: " ", truncationMarker: nil)
                XCTAssertEqual(0, result.count, "\(str) \(limit)")
            }
        }

        // Above the limit below String(repeating::) crashes with a memory error.
        // Commented out for nonsensical use resources.
        // let upperLimit = Int(pow(Double(2), Double(46))  * 1.993)
        // XCTAssertEqual(upperLimit, strings[1].fitted(to: upperLimit, withPad: " ", truncationMarker: nil).count, String(upperLimit))
    }

}

fileprivate struct TestCase {
    let test: String
    let exp: String
    let length: Int
}
