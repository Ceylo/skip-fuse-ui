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
/// attributes instead — see `RichTextEncoding`, which `TextRunStyle` also emits, so a
/// styled string and a `Text + Text` operand provably agree on the format.
extension AttributedString {
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

            var baseline = ""
            if let offset = run.baselineOffset, offset != 0 {
                baseline = offset > 0 ? "super" : "sub"
            }

            let record = RichTextEncoding.record(
                text: text,
                weight: weight?.value,
                isItalic: font?.isItalic == true,
                isMonospaced: isMonospaced,
                size: size.map { Double($0) },
                color: run.foregroundColor.flatMap { RichTextEncoding.token(for: $0.spec) },
                isUnderlined: run.underlineStyle != nil,
                isStruckThrough: run.strikethroughStyle != nil,
                baseline: baseline,
                link: run.link?.absoluteString ?? "",
                inlineViewIndex: inlineIndex,
                inlineViewWidth: inlineView.map { $0.width },
                inlineViewHeight: inlineView.map { $0.height }
            )
            if RichTextEncoding.isStyled(record) {
                isStyled = true
            }
            records.append(record)
        }

        return isStyled ? records.joined(separator: RichTextEncoding.recordSeparator) : nil
        #endif
    }
}
