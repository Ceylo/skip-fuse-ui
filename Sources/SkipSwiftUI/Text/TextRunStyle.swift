// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !ROBOLECTRIC && canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation

/// The wire format `SkipUI.RichText` reads: one record per styled span, separated by
/// ASCII RS; one field per attribute within a record, separated by ASCII US.
///
/// Two encoders emit it — `AttributedString.richTextRepresentation` for a styled string,
/// and `TextRunStyle` for one operand of a `Text + Text` — so the field order and the
/// colour spelling live here rather than in either of them.
enum RichTextEncoding {
    static let recordSeparator = "\u{001E}"
    static let fieldSeparator = "\u{001F}"

    static func record(
        text: String,
        weight: Int? = nil,
        isItalic: Bool = false,
        isMonospaced: Bool = false,
        size: Double? = nil,
        color: String? = nil,
        isUnderlined: Bool = false,
        isStruckThrough: Bool = false,
        baseline: String = "",
        link: String = "",
        inlineViewIndex: Int? = nil,
        inlineViewWidth: Double? = nil,
        inlineViewHeight: Double? = nil
    ) -> String {
        var decorations = ""
        if isUnderlined { decorations += "u" }
        if isStruckThrough { decorations += "s" }
        let fields = [
            sanitized(text),
            weight.map { String($0) } ?? "",
            isItalic ? "1" : "",
            isMonospaced ? "1" : "",
            size.map { String($0) } ?? "",
            color ?? "",
            decorations,
            baseline,
            sanitized(link),
            inlineViewIndex.map { String($0) } ?? "",
            inlineViewWidth.map { String($0) } ?? "",
            inlineViewHeight.map { String($0) } ?? "",
        ]
        return fields.joined(separator: fieldSeparator)
    }

    /// Whether a record says anything beyond its text, i.e. whether it is worth the
    /// encode/decode round trip at all.
    static func isStyled(_ record: String) -> Bool {
        return record.components(separatedBy: fieldSeparator)
            .dropFirst()
            .contains { !$0.isEmpty }
    }

    /// A decimal ARGB literal, or the name of a token the composition resolves against
    /// the current theme. `nil` for anything else, which inherits.
    static func token(for spec: ColorSpec) -> String? {
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
    static func argb(red: Double, green: Double, blue: Double, alpha: Double) -> String {
        func byte(_ component: Double) -> Int64 {
            Int64((min(max(component, 0), 1) * 255).rounded())
        }
        let packed = byte(alpha) << 24 | byte(red) << 16 | byte(green) << 8 | byte(blue)
        return String(packed)
    }

    /// The separators are structural, so they can never appear inside a field.
    static func sanitized(_ text: String) -> String {
        guard text.contains(recordSeparator) || text.contains(fieldSeparator) else {
            return text
        }
        return text
            .replacingOccurrences(of: recordSeparator, with: "")
            .replacingOccurrences(of: fieldSeparator, with: "")
    }
}

/// One operand's styling of a `Text + Text`, as data.
///
/// A `Text`'s modifiers are otherwise stored as closures applying *environment-based
/// view* modifiers, which is exactly what a concatenation cannot use: Compose needs one
/// `AnnotatedString` with a `SpanStyle` per segment, so the styling has to be readable.
/// Each modifier records here in addition to appending to `modifierChain`, so a
/// standalone `Text` keeps behaving exactly as before.
struct TextRunStyle : Hashable, Sendable {
    var weight: Int?
    var isItalic = false
    var isMonospaced = false
    var size: Double?
    var color: String?
    var isUnderlined = false
    var isStruckThrough = false
    /// Modifiers that cannot cross as a `SpanStyle`. Named, so concatenating a `Text`
    /// carrying one fails loudly rather than dropping it.
    var unsupported: [String] = []

    /// This operand's record, with the text field left empty: the segment's own `Text`
    /// crosses alongside it and resolves its text at compose time, so that keys, tables,
    /// bundles and locale behave exactly as they would for a standalone `Text`.
    var record: String {
        RichTextEncoding.record(
            text: "",
            weight: weight,
            isItalic: isItalic,
            isMonospaced: isMonospaced,
            size: size,
            color: color,
            isUnderlined: isUnderlined,
            isStruckThrough: isStruckThrough
        )
    }

    /// Records everything a `Font` says that a `SpanStyle` can carry.
    mutating func apply(font: Font?) {
        guard let spec = font?.spec else { return }
        weight = spec.weight?.value ?? weight
        isItalic = isItalic || spec.isItalic
        isMonospaced = isMonospaced || spec.design == .monospaced
        var resolved = spec.size
        switch spec.type {
        case .system(_, let design, let typeWeight):
            weight = weight ?? typeWeight?.value
            isMonospaced = isMonospaced || design == .monospaced
        case .systemSize(let typeSize, let design, let typeWeight):
            weight = weight ?? typeWeight?.value
            isMonospaced = isMonospaced || design == .monospaced
            resolved = resolved ?? typeSize
        case .customSize(_, let typeSize), .customFixedSize(_, let typeSize),
             .customRelativeSize(_, let typeSize, _):
            resolved = resolved ?? typeSize
            unsupported.append("font(.custom)")
        case .java:
            break
        }
        if let scaledBy = spec.scaledBy, let unscaled = resolved {
            resolved = unscaled * scaledBy
        }
        size = resolved.map { Double($0) } ?? size
    }
}
