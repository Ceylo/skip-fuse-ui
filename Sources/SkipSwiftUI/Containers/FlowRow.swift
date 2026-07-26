// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !ROBOLECTRIC && canImport(CoreGraphics)
import CoreGraphics
#endif
import SkipFuse
import SkipUI

/// A leading-aligned row that wraps onto additional lines.
///
/// SwiftUI expresses this with the `Layout` protocol, which SkipSwiftUI does not have;
/// Compose has it natively, so it is a container here instead.
public struct FlowRow<Content> : View where Content : View {
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let content: Content

    public init(spacing: CGFloat = 8.0, lineSpacing: CGFloat = 8.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content()
    }

    public typealias Body = Never
}

extension FlowRow : SkipUIBridging {
    public var Java_view: any SkipUI.View {
        return SkipUI.FlowRow(spacing: spacing, lineSpacing: lineSpacing, bridgedContent: content.Java_viewOrEmpty)
    }
}
