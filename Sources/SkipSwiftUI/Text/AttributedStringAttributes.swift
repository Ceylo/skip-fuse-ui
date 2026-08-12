// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !ROBOLECTRIC && canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation

// Darwin builds get the real thing from SwiftUI, and declaring a second scope of the
// same name there makes `AttributeScopes.SwiftUIAttributes` ambiguous.
#if !canImport(Darwin)

/// SwiftUI's own `AttributedString` attributes.
///
/// Corelibs Foundation carries custom `AttributedStringKey`s fine but has no
/// `InlinePresentationIntent`/`PresentationIntent`, so styling an `AttributedString`
/// for Compose means spelling runs the way SwiftUI does — `run.font`, `run.foregroundColor`
/// and friends. Only the subset the rich-text bridge can actually render is declared;
/// see `AttributedString.richTextRepresentation`.
extension AttributeScopes {
    public struct SwiftUIAttributes : AttributeScope {
        public let font: FontAttribute
        public let foregroundColor: ForegroundColorAttribute
        public let backgroundColor: BackgroundColorAttribute
        public let underlineStyle: UnderlineStyleAttribute
        public let strikethroughStyle: StrikethroughStyleAttribute
        public let baselineOffset: BaselineOffsetAttribute

        public enum FontAttribute : AttributedStringKey {
            public typealias Value = Font
            public static let name = "SwiftUI.Font"
        }

        public enum ForegroundColorAttribute : AttributedStringKey {
            public typealias Value = Color
            public static let name = "SwiftUI.ForegroundColor"
        }

        public enum BackgroundColorAttribute : AttributedStringKey {
            public typealias Value = Color
            public static let name = "SwiftUI.BackgroundColor"
        }

        public enum UnderlineStyleAttribute : AttributedStringKey {
            public typealias Value = Text.LineStyle
            public static let name = "SwiftUI.UnderlineStyle"
        }

        public enum StrikethroughStyleAttribute : AttributedStringKey {
            public typealias Value = Text.LineStyle
            public static let name = "SwiftUI.StrikethroughStyle"
        }

        public enum BaselineOffsetAttribute : AttributedStringKey {
            public typealias Value = CGFloat
            public static let name = "SwiftUI.BaselineOffset"
        }
    }

    public var swiftUI: SwiftUIAttributes.Type {
        SwiftUIAttributes.self
    }
}

extension AttributeDynamicLookup {
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.SwiftUIAttributes, T>
    ) -> T {
        self[T.self]
    }
}

#endif
