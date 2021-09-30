//  © 2021 Ryan Ferrell. github.com/importRyan


import XCTest

class AssertMultilineStringsEqualTests: XCTestCase {

    func testToleratesEndOfLineWhitespaces() {

        TestCases.unequal.enumerated().forEach { (i, testCase) in
            XCTExpectFailure("Cases must fail", strict: true) {
                AssertMultilineStringsEqual(exp: testCase.exp, result: testCase.res, tolerateEndOfLineWhitespaces: true, message: String(i))
            }
        }

        TestCases.unequalByTrailingWhitespaces.enumerated().forEach { (i, testCase) in
            AssertMultilineStringsEqual(exp: testCase.exp, result: testCase.res, tolerateEndOfLineWhitespaces: true, message: String(i))

        }

        TestCases.equal.enumerated().forEach { (i, testCase) in
            AssertMultilineStringsEqual(exp: testCase.exp, result: testCase.res, tolerateEndOfLineWhitespaces: true, message: String(i))
        }
    }

    func testEvaluatesEndOfLineWhitespaces() {

        TestCases.unequal.enumerated().forEach { (i, testCase) in
            XCTExpectFailure("Cases must fail", strict: true) {
                AssertMultilineStringsEqual(exp: testCase.exp, result: testCase.res, tolerateEndOfLineWhitespaces: false, message: String(i))
            }
        }

        TestCases.unequalByTrailingWhitespaces.enumerated().forEach { (i, testCase) in
            XCTExpectFailure("Cases must fail", strict: true) {
                AssertMultilineStringsEqual(exp: testCase.exp, result: testCase.res, tolerateEndOfLineWhitespaces: false, message: String(i))
            }
        }

        TestCases.equal.forEach { (exp, result) in
            AssertMultilineStringsEqual(exp: exp, result: result, tolerateEndOfLineWhitespaces: false)
        }
    }
}

fileprivate enum TestCases {

    static let unequal: [(exp: String, res: String)] = [
        ("\nx\n", "\n\n z"),
        ("\n y\n", "b\n\n ")
    ]

    static let unequalByTrailingWhitespaces: [(exp: String, res: String)] = [
        ("\n\n", "\n\n "),
        ("\n \n", "\n\n ")
    ]

    static let equal: [(exp: String, res: String)] = [
        ("\n\n", "\n\n"),
        ("""
""", """

"""),
        ("""
""", """

"""),
    ]
}
