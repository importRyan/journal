//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public class JJStaticFormattingStore: JJFormatting {

    public var current: JJEntryFormatting

    public init(formatter: JJEntryFormatting) {
        self.current = formatter
    }
}
