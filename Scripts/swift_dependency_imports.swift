import Foundation
import SwiftParser
import SwiftSyntax

private struct ImportRecord: Encodable {
    let path: String
    let line: Int
    let module: String
    let declaration: String
}

private final class ImportVisitor: SyntaxVisitor {
    private let path: String
    private let converter: SourceLocationConverter
    private let encoder = JSONEncoder()

    init(path: String, tree: SourceFileSyntax) {
        self.path = path
        converter = SourceLocationConverter(fileName: path, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let firstComponent = node.path.first else {
            fail("import declaration has no module path in \(path)")
        }
        let record = ImportRecord(
            path: path,
            line: converter.location(
                for: node.importKeyword.positionAfterSkippingLeadingTrivia
            ).line,
            module: normalizedIdentifier(firstComponent.name.text),
            declaration: node.trimmedDescription
        )
        do {
            let data = try encoder.encode(record)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([0x0A]))
        } catch {
            fail("cannot encode import declaration in \(path): \(error)")
        }
        return .skipChildren
    }
}

private func normalizedIdentifier(_ value: String) -> String {
    guard value.first == "`", value.last == "`" else {
        return value
    }
    return String(value.dropFirst().dropLast())
}

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    Foundation.exit(2)
}

guard CommandLine.arguments.count > 1 else {
    fail("expected at least one Swift source path")
}

for path in CommandLine.arguments.dropFirst() {
    let source: String
    do {
        source = try String(contentsOfFile: path, encoding: .utf8)
    } catch {
        fail("cannot read \(path): \(error)")
    }

    let tree = Parser.parse(source: source)
    guard !tree.hasError else {
        fail("Swift parser reported syntax errors in \(path)")
    }
    ImportVisitor(path: path, tree: tree).walk(tree)
}
