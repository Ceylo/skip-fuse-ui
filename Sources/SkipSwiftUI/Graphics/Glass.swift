// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !ROBOLECTRIC && canImport(CoreGraphics)
import CoreGraphics
#endif
import SkipBridge
import SkipUI

public struct Glass : Equatable, Sendable {
    public static var regular: Glass {
        return Glass()
    }

    public func tint(_ color: Color?) -> Glass {
        return self
    }

    public func interactive(_ isEnabled: Bool = true) -> Glass {
        return self
    }
}

/// A pass-through, like `glassEffect`: without it a shared source's glass branch, taken
/// because `#available(iOS 26, *)` is vacuously true off-Apple, does not compile. It
/// bridges as a `Group`, since a `body` alone reaches Compose as nothing.
public struct GlassEffectContainer<Content> {
    let content: Content

    public typealias Body = Never
}

extension GlassEffectContainer : View where Content : View {
    nonisolated public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

extension GlassEffectContainer : SkipUIBridging {
    public var Java_view: any SkipUI.View {
        return SkipUI.Group(bridgedContent: (content as? any SkipUIBridging)?.Java_view ?? SkipUI.EmptyView())
    }
}

public struct GlassEffectTransition : Sendable {
    @available(*, unavailable)
    public static var matchedGeometry: GlassEffectTransition {
        return GlassEffectTransition()
    }

    @available(*, unavailable)
    public static func matchedGeometry(properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center) -> GlassEffectTransition {
        return GlassEffectTransition()
    }

    public static var identity: GlassEffectTransition {
        return GlassEffectTransition()
    }
}

extension View {
    /// Compose has no Liquid Glass, so SkipUI draws the Material 3 floating-control
    /// surface in `shape` instead. `glass` is ignored.
    nonisolated public func glassEffect(_ glass: Glass = .regular, in shape: some Shape = .capsule, isEnabled: Bool = true) -> some View {
        return ModifierView(target: self) {
            $0.Java_viewOrEmpty.glassEffect(bridgedShape: shape.Java_shape, isEnabled: isEnabled)
        }
    }

    @MainActor @preconcurrency public func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true) -> some View {
        // We only support .identity
        return self
    }

    /// A pass-through: `#available(iOS 26, *)` is vacuously true off-Apple, so shared
    /// sources take their glass branch, and each glass shape draws on its own.
    @MainActor @preconcurrency public func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View {
        return self
    }

    /// A pass-through, like `glassEffectUnion`.
    nonisolated public func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View {
        return self
    }
}
