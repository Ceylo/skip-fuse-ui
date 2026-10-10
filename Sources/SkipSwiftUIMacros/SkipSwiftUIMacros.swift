// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SkipSwiftUIMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PreviewMacro.self,
        PreviewableMacro.self,
        EntryMacro.self,
        EntryDefaultValueMacro.self,
    ]
}
