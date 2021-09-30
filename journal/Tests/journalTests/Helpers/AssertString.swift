//  © 2021 Ryan Ferrell. github.com/importRyan


import XCTest

extension XCTestCase {

    func AssertMultilineStringsEqual(exp: String, result res: String, tolerateEndOfLineWhitespaces: Bool,
                                     file: StaticString = #file, line: UInt = #line, message: String? = nil) {

        let unwrappedMessage = message == nil ? "" : message! + " "

        let expLines = exp.components(separatedBy: .newlines)
        let resLines = res.components(separatedBy: .newlines)
        let lineCounts = (expLines.endIndex, resLines.endIndex)
        let content = (exp.filter { !$0.isWhitespace }, res.filter { !$0.isWhitespace })
        let commonContentPrefix = content.0.commonPrefix(with: content.1)

        XCTAssertEqual(lineCounts.0, lineCounts.1, "\(unwrappedMessage)Line Count", file: file, line: line)
        XCTAssertEqual(content.0.count, content.1.count, "\(unwrappedMessage)Non-whitespace Characters", file: file, line: line)
        XCTAssertEqual(content.0, commonContentPrefix, "\(unwrappedMessage)Prefix Non-whitespaces \(commonContentPrefix.count) of \(content.0.count)", file: file, line: line)

        if tolerateEndOfLineWhitespaces {

            zip(expLines, resLines).enumerated().forEach { (index, pair) in

                let prefixWhitespaces = (pair.0.prefix(while: \.isWhitespace), pair.1.prefix(while: \.isWhitespace))
                let contentOnly = (pair.0.trimmingCharacters(in: .whitespaces), pair.1.trimmingCharacters(in: .whitespaces))

                // Skip lines with only whitespace
                if contentOnly.0.isEmpty && contentOnly.1.isEmpty { return }

                XCTAssertEqual(prefixWhitespaces.0, prefixWhitespaces.1,
                               "\(unwrappedMessage)Line \(index) Prefix Whitespaces", file: file, line: line)
                XCTAssertEqual(contentOnly.0, contentOnly.1,
                               "\(unwrappedMessage)Line \(index) Trimmed Content", file: file, line: line)
            }

        } else {

            let expLength = exp.count
            let resultLength = res.count
            let commonPrefix = exp.commonPrefix(with: res)
            let commonSuffix = exp.commonPrefix(with: res, options: .backwards)
            let whitespaces = (
                exp.filter(\.isWhitespace).count - exp.filter(\.isNewline).count,
                res.filter(\.isWhitespace).count - res.filter(\.isNewline).count
            )

            XCTAssertEqual(expLength, resultLength, "\(unwrappedMessage)Total Character Count", file: file, line: line)
            XCTAssertEqual(whitespaces.0, whitespaces.1, "\(unwrappedMessage)Whitespaces", file: file, line: line)
            XCTAssertEqual(exp, commonPrefix, "\(unwrappedMessage)Prefix of \(commonPrefix.count)", file: file, line: line)
            XCTAssertEqual(exp, commonSuffix, "\(unwrappedMessage)Suffix of \(commonSuffix.count)", file: file, line: line)
        }

        if content.0 != content.1 {
            NSLog(res)
        }
    }
}
