// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation

/// SkipUI's rich-text model is markdown: `SkipUI.Text` renders an `AttributedString`
/// through its `MarkdownNode`. So a Foundation `AttributedString` reaches Compose by
/// being re-emitted as markdown and parsed on the other side.
extension AttributedString {
    /// A markdown rendering of the receiver, or `nil` if it needs no markdown at all.
    ///
    /// `nil` matters: SkipUI only builds a `MarkdownNode` when the text actually
    /// contains a link or emphasis construct, and renders the source string verbatim
    /// otherwise — which would show our backslash escapes. Callers pass the plain
    /// string through as `verbatim` in that case.
    var markdownRepresentation: String? {
        var markdown = ""
        var needsMarkdown = false

        for run in runs {
            let text = String(self[run.range].characters)
            guard !text.isEmpty else { continue }

            var escaped = Self.escapingMarkdown(text)

            #if canImport(Darwin)
            if let intent = run.inlinePresentationIntent {
                if intent.contains(.stronglyEmphasized) {
                    escaped = "**\(escaped)**"
                    needsMarkdown = true
                }
                if intent.contains(.emphasized) {
                    escaped = "*\(escaped)*"
                    needsMarkdown = true
                }
                if intent.contains(.strikethrough) {
                    escaped = "~\(escaped)~"
                    needsMarkdown = true
                }
            }
            #endif

            if let link = run.link {
                // Angle-bracket form so URLs with spaces or parentheses stay intact.
                escaped = "[\(escaped)](<\(Self.escapingLinkDestination(link.absoluteString))>)"
                needsMarkdown = true
            }

            markdown += escaped
        }

        return needsMarkdown ? markdown : nil
    }

    /// Backslash-escapes the CommonMark inline specials. SkipUI parses with block
    /// types disabled, so only inline constructs can be triggered.
    private static func escapingMarkdown(_ text: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(text.count)
        for character in text {
            if #"\`*_[]<>~&!"#.contains(character) {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }

    private static func escapingLinkDestination(_ destination: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(destination.count)
        for character in destination {
            if #"\<>"#.contains(character) {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }
}
