//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public extension String {

    /// Pads or truncates a string to fit the desired Character length. O(k) where k == desired Character length.
    ///
    /// Foundation's method String.padding(toLength:::) uses (UTF-16 code units, rather than Characters.)[https://forums.swift.org/t/string-padding-method-is-broken/14417].
    ///
    func fitted(to length: Int, withPad: Character = " ", truncationMarker: Character? = nil) -> String {
        guard length > 0 else { return "" }

        let substring = self.prefix(length)
        let substringLengthDifference = length - substring.count

            // If too short, add padding
        if substringLengthDifference > 0 {
            let pad = String(repeating: withPad, count: substringLengthDifference)
            return substring.appending(pad)

            // If truncation desired and string doesn't end w/ the substring
        } else if let marker = truncationMarker, substring.endIndex < self.endIndex {
            return substring.dropLast(1).appending(String(marker))

            // If truncated and no marker required
        } else {
            return String(substring)
        }
    }
}

public extension Character {
    static let ellipsis: Character = "…"
}
