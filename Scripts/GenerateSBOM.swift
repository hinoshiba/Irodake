import Foundation

struct SPDXDocument: Encodable {
    let spdxVersion = "SPDX-2.3"
    let dataLicense = "CC0-1.0"
    let SPDXID = "SPDXRef-DOCUMENT"
    let name: String
    let documentNamespace: String
    let creationInfo: CreationInfo
    let packages: [Package]
    let relationships: [Relationship]
}

struct CreationInfo: Encodable {
    let created: String
    let creators = ["Tool: Irodake-GenerateSBOM"]
}

struct Package: Encodable {
    let name: String
    let SPDXID: String
    let versionInfo: String
    let downloadLocation: String
    let filesAnalyzed = false
    let licenseConcluded = "MIT"
    let licenseDeclared = "MIT"
    let copyrightText = "Copyright (c) 2026 hinoshiba"
    let externalRefs: [ExternalRef]
}

struct ExternalRef: Encodable {
    let referenceCategory = "PACKAGE-MANAGER"
    let referenceType = "purl"
    let referenceLocator: String
}

struct Relationship: Encodable {
    let spdxElementId: String
    let relationshipType: String
    let relatedSpdxElement: String
}

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: swift Scripts/GenerateSBOM.swift <version> <git-sha> <output.spdx.json>\n", stderr)
    exit(1)
}

let version = CommandLine.arguments[1]
let revision = CommandLine.arguments[2]
let output = URL(fileURLWithPath: CommandLine.arguments[3])
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime]

let document = SPDXDocument(
    name: "Irodake-\(version)",
    documentNamespace: "https://github.com/hinoshiba/Irodake/sbom/\(version)/\(revision)",
    creationInfo: CreationInfo(created: formatter.string(from: Date())),
    packages: [
        Package(
            name: "Irodake",
            SPDXID: "SPDXRef-Package-Irodake",
            versionInfo: version,
            downloadLocation: "https://github.com/hinoshiba/Irodake/tree/\(revision)",
            externalRefs: [
                ExternalRef(referenceLocator: "pkg:github/hinoshiba/Irodake@\(revision)")
            ]
        ),
    ],
    relationships: [
        Relationship(
            spdxElementId: "SPDXRef-DOCUMENT",
            relationshipType: "DESCRIBES",
            relatedSpdxElement: "SPDXRef-Package-Irodake"
        ),
    ]
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
try encoder.encode(document).write(to: output, options: .atomic)
print("Created \(output.path)")
