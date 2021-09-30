//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
@testable import Journaling

enum MockEntry {

    static func make(title: String) -> JJEntry {
        JJEntry(title: title, content: "Original Content")
    }

    static func make(count: Int) -> [JJEntry] {
        (1...count).map {
            JJEntry(
                title: "Original Title \($0)",
                content: String("Original Content \($0)")
            ) }
    }

    static let original = JJEntry(title: "Original Title", content: "Original Content")
}

