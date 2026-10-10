// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import SwiftSyntax
import SwiftSyntaxMacros

/// `@Entry` on an `EnvironmentValues` property, expanded as SwiftUI does: a `get`/`set`
/// pair over a private `__Key_<name>` peer whose `defaultValue` is the initializer.
public struct EntryMacro: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        let entry = try Entry(declaration, in: context)
        return [
            "get { self[\(entry.keyName).self] }",
            "set { self[\(entry.keyName).self] = newValue }",
        ]
    }

    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // The accessor expansion already diagnosed an invalid declaration.
        guard let entry = try? Entry(declaration, in: context) else {
            return []
        }
        // The helper macro makes both computed, so each read gets a fresh value and there
        // is no global mutable state, while their type can still be inferred from the
        // initializer. As in SwiftUI, the initializer lives in a static of the extended
        // type, where `Self` and its private members resolve as they do at the call site.
        let defaultValue = context.makeUniqueName("defaultValue")
        return [
            "@SwiftUI.__EntryDefaultValue private static var \(defaultValue)\(entry.typeAnnotation) = \(entry.initializer)",
            """
            private struct \(entry.keyName): SwiftUI.EnvironmentKey {
                @SwiftUI.__EntryDefaultValue static var defaultValue\(entry.typeAnnotation) = \(defaultValue)
            }
            """,
        ]
    }
}

/// Turns `static var defaultValue = <expr>` into a getter returning `<expr>`.
public struct EntryDefaultValueMacro: AccessorMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        guard let initializer = declaration.as(VariableDeclSyntax.self)?.bindings.first?.initializer?.value else {
            return []
        }
        return ["get { \(initializer.trimmed) }"]
    }
}

private struct Entry {
    let keyName: TokenSyntax
    let typeAnnotation: TypeAnnotationSyntax?
    let initializer: ExprSyntax

    init(_ declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws {
        // SkipSwiftUI has no Transaction, FocusedValues or ContainerValues keys to target.
        guard let extendedType = context.lexicalContext.first?.as(ExtensionDeclSyntax.self)?.extendedType,
              extendedType.trimmedDescription.split(separator: ".").last == "EnvironmentValues" else {
            throw MacroExpansionErrorMessage("'@Entry' is only supported in an 'EnvironmentValues' extension on Android")
        }
        guard let variable = declaration.as(VariableDeclSyntax.self), variable.bindingSpecifier.tokenKind == .keyword(.var),
              !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) else {
            throw MacroExpansionErrorMessage("'@Entry' can only be applied to an instance 'var' declaration")
        }
        guard variable.bindings.count == 1, let binding = variable.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw MacroExpansionErrorMessage("'@Entry' requires a single named property")
        }
        guard binding.accessorBlock == nil else {
            throw MacroExpansionErrorMessage("'@Entry' cannot be applied to a property with accessors or observers")
        }
        let typeAnnotation = binding.typeAnnotation?.trimmed
        if binding.initializer == nil && !(typeAnnotation?.type.isOptional ?? false) {
            throw MacroExpansionErrorMessage("'@Entry' requires a default value, or an optional type")
        }
        // `identifier` drops the backticks of an escaped name such as `default`.
        self.keyName = "__Key_\(raw: name.identifier?.name ?? name.text)"
        self.typeAnnotation = typeAnnotation
        self.initializer = binding.initializer?.value.trimmed ?? "nil"
    }
}

private extension TypeSyntax {
    var isOptional: Bool {
        `is`(OptionalTypeSyntax.self) || `is`(ImplicitlyUnwrappedOptionalTypeSyntax.self)
            || self.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
            || self.as(MemberTypeSyntax.self).map { $0.baseType.trimmedDescription == "Swift" && $0.name.text == "Optional" } == true
    }
}
