// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import SkipSwiftUI

/// `@Entry`, for declaring an `EnvironmentValues` property without a hand-written key.
@attached(accessor) @attached(peer, names: prefixed(__Key_))
public macro Entry() = #externalMacro(module: "SkipSwiftUIMacros", type: "EntryMacro")

/// Implementation detail of `@Entry`.
@attached(accessor)
public macro __EntryDefaultValue() = #externalMacro(module: "SkipSwiftUIMacros", type: "EntryDefaultValueMacro")
