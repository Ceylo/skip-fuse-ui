// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import SkipSwiftUI

// `#Preview` and `@Previewable`, so that a SwiftUI file with previews builds for Android
// without `#if` guards. There is no canvas on Android: the macros expand to nothing, but
// the preview body is still type-checked.

@freestanding(declaration)
public macro Preview(_ name: String? = nil, @ViewBuilder body: @escaping @MainActor () -> any View) = #externalMacro(module: "SkipPreviewMacros", type: "PreviewMacro")

@freestanding(declaration)
public macro Preview(_ name: String? = nil, traits: PreviewTrait<Preview.ViewTraits>, _ additionalTraits: PreviewTrait<Preview.ViewTraits>..., @ViewBuilder body: @escaping @MainActor () -> any View) = #externalMacro(module: "SkipPreviewMacros", type: "PreviewMacro")

@attached(peer)
public macro Previewable() = #externalMacro(module: "SkipPreviewMacros", type: "PreviewableMacro")

public struct Preview {
    public struct ViewTraits {
    }
}

public struct PreviewTrait<T> {
    init() {
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    public static var defaultLayout: PreviewTrait<T> { PreviewTrait() }
    public static var sizeThatFitsLayout: PreviewTrait<T> { PreviewTrait() }
    public static func fixedLayout(width: CGFloat, height: CGFloat) -> PreviewTrait<T> { PreviewTrait() }
    public static var portrait: PreviewTrait<T> { PreviewTrait() }
    public static var portraitUpsideDown: PreviewTrait<T> { PreviewTrait() }
    public static var landscapeLeft: PreviewTrait<T> { PreviewTrait() }
    public static var landscapeRight: PreviewTrait<T> { PreviewTrait() }
}
