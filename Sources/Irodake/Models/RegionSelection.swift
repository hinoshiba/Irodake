import CoreGraphics
import Foundation

struct RegionSelection: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case rectangle
        case window
    }

    let id: UUID
    var kind: Kind
    var frame: CGRect
    var name: String
    var applicationName: String?
    var ownerPID: Int32?
    var windowID: UInt32?
    var isVisible: Bool?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        frame: CGRect,
        name: String,
        applicationName: String? = nil,
        ownerPID: Int32? = nil,
        windowID: UInt32? = nil,
        isVisible: Bool? = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.frame = frame.standardized
        self.name = name
        self.applicationName = applicationName
        self.ownerPID = ownerPID
        self.windowID = windowID
        self.isVisible = isVisible
        self.createdAt = createdAt
    }

    var systemImage: String {
        switch kind {
        case .rectangle: "rectangle.dashed"
        case .window: "macwindow"
        }
    }
}

struct WindowCandidate: Identifiable, Equatable {
    let id: UInt32
    let title: String
    let applicationName: String
    let ownerPID: Int32
    let frame: CGRect

    var displayName: String {
        title.isEmpty ? applicationName : title
    }
}
