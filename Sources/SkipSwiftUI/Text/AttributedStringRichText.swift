// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !ROBOLECTRIC && canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation

/// Encodes an `AttributedString` for `SkipUI.Text(bridgedRichText:)`.
///
/// Markdown was the obvious bridge and is not enough: it cannot express colour, font
/// size, underline or baseline at all. So each run crosses as a record of its
/// attributes instead — one record per run separated by ASCII RS, one field per
/// attribute separated by ASCII US, in the order `SkipUI.RichText` reads them.
extension AttributedString {
    private static let recordSeparator = "\u{001E}"
    private static let fieldSeparator = "\u{001F}"

    /// The object-replacement character, which marks where an inline view goes — the
    /// same one `NSAttributedString` uses for an attachment.
    static let attachmentCharacter: Character = "\u{FFFC}"

    /// The receiver as a rich-text payload, or `nil` if it carries no attribute the
    /// bridge can render.
    ///
    /// `nil` matters: a string with no styling should reach Compose as a plain
    /// `Text(verbatim:)` rather than paying for the encode/decode round trip.
    func richTextRepresentation(inlineViews: [TextInlineView] = []) -> String? {
        #if canImport(Darwin)
        // Only the Android build renders through SkipUI; the Darwin compile of this
        // module is a typecheck of the bridge. There `run.font` is SwiftUI's own opaque
        // `Font` rather than a `FontSpec` to read, so there is nothing to encode.
        return nil
        #else
        var records: [String] = []
        var isStyled = false
        var inlineViewIndex = 0

        for run in runs {
            let text = String(self[run.range].characters)
            guard !text.isEmpty else { continue }

            // Attachment runs consume the inline views in order. Any beyond the ones
            // supplied are dropped rather than left to draw as a tofu box.
            var inlineView: TextInlineView?
            var inlineIndex: Int?
            if text.count == 1, text.first == Self.attachmentCharacter {
                guard inlineViewIndex < inlineViews.count else { continue }
                inlineView = inlineViews[inlineViewIndex]
                inlineIndex = inlineViewIndex
                inlineViewIndex += 1
                isStyled = true
            }

            let font = run.font?.spec
            var weight = font?.weight
            var isMonospaced = font?.design == .monospaced
            var size = font?.size
            if let type = font?.type {
                switch type {
                case .system(_, let design, let typeWeight):
                    weight = weight ?? typeWeight
                    isMonospaced = isMonospaced || design == .monospaced
                case .systemSize(let typeSize, let design, let typeWeight):
                    weight = weight ?? typeWeight
                    isMonospaced = isMonospaced || design == .monospaced
                    size = size ?? typeSize
                case .customSize(_, let typeSize), .customFixedSize(_, let typeSize),
                     .customRelativeSize(_, let typeSize, _):
                    size = size ?? typeSize
                case .java:
                    break
                }
            }
            if let scaledBy = font?.scaledBy, let unscaled = size {
                size = unscaled * scaledBy
            }

            var decorations = ""
            if run.underlineStyle != nil { decorations += "u" }
            if run.strikethroughStyle != nil { decorations += "s" }

            var baseline = ""
            if let offset = run.baselineOffset, offset != 0 {
                baseline = offset > 0 ? "super" : "sub"
            }

            let color = run.foregroundColor.flatMap { Self.token(for: $0.spec) }
            let fields = [
                Self.sanitized(text),
                weight.map { String($0.value) } ?? "",
                font?.isItalic == true ? "1" : "",
                isMonospaced ? "1" : "",
                size.map { String(Double($0)) } ?? "",
                color ?? "",
                decorations,
                baseline,
                run.link.map { Self.sanitized($0.absoluteString) } ?? "",
                inlineIndex.map { String($0) } ?? "",
                inlineView.map { String($0.width) } ?? "",
                inlineView.map { String($0.height) } ?? "",
            ]
            if fields.dropFirst().contains(where: { !$0.isEmpty }) {
                isStyled = true
            }
            records.append(fields.joined(separator: Self.fieldSeparator))
        }

        return isStyled ? records.joined(separator: Self.recordSeparator) : nil
        #endif
    }

    /// A decimal ARGB literal, or the name of a token the composition resolves against
    /// the current theme. `nil` for anything else, which inherits.
    private static func token(for spec: ColorSpec) -> String? {
        switch spec.type {
        case .primary:
            return "primary"
        case .secondary:
            return "secondary"
        case .accent:
            return "accent"
        case .rgb(let red, let green, let blue, let alpha):
            return argb(red: red, green: green, blue: blue, alpha: alpha * spec.opacity)
        case .w(let white, let alpha):
            return argb(red: white, green: white, blue: white, alpha: alpha * spec.opacity)
        default:
            return nil
        }
    }

    /// Decimal rather than hex: SkipLib's `Int64(_ string:)` has no radix parameter.
    private static func argb(red: Double, green: Double, blue: Double, alpha: Double) -> String {
        func byte(_ component: Double) -> Int64 {
            Int64((min(max(component, 0), 1) * 255).rounded())
        }
        let packed = byte(alpha) << 24 | byte(red) << 16 | byte(green) << 8 | byte(blue)
        return String(packed)
    }

    /// The separators are structural, so they can never appear inside a field.
    private static func sanitized(_ text: String) -> String {
        guard text.contains(recordSeparator) || text.contains(fieldSeparator) else {
            return text
        }
        return text
            .replacingOccurrences(of: recordSeparator, with: "")
            .replacingOccurrences(of: fieldSeparator, with: "")
    }
}
