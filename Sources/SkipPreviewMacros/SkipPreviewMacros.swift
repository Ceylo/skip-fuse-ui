// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

/// `#Preview` on Android: there is no canvas to register a preview with, so it expands to
/// nothing. Its arguments, the preview body included, are still type-checked against the
/// macro's signature, so a preview that no longer compiles fails the Android build too.
public struct PreviewMacro: DeclarationMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        []
    }
}

/// `@Previewable` on Android: only needs to exist so that preview bodies type-check.
public struct PreviewableMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        []
    }
}

@main
struct SkipPreviewMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [PreviewMacro.self, PreviewableMacro.self]
}
