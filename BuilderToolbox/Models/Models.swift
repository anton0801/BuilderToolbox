import Foundation
import SwiftUI

// MARK: - User
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var createdAt: Date = Date()
}

// MARK: - Project
struct Project: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var apartmentType: String
    var rooms: [Room] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var totalArea: Double {
        rooms.reduce(0) { $0 + $1.area }
    }
}

// MARK: - Room
struct Room: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var type: RoomType
    var width: Double
    var length: Double
    var area: Double { width * length }
    var measurements: [Measurement] = []
    var furniture: [FurnitureItem] = []
    var walls: [Wall] = []
    var createdAt: Date = Date()
}

enum RoomType: String, Codable, CaseIterable {
    case livingRoom = "Living Room"
    case kitchen = "Kitchen"
    case bedroom = "Bedroom"
    case bathroom = "Bathroom"
    case hallway = "Hallway"
    case diningRoom = "Dining Room"
    case office = "Office"
    case storage = "Storage"

    var icon: String {
        switch self {
        case .livingRoom: return "sofa"
        case .kitchen: return "fork.knife"
        case .bedroom: return "bed.double"
        case .bathroom: return "shower"
        case .hallway: return "door.left.hand.open"
        case .diningRoom: return "chair"
        case .office: return "desktopcomputer"
        case .storage: return "archivebox"
        }
    }

    var color: Color {
        switch self {
        case .livingRoom: return Color(hex: "#2D7DD2")
        case .kitchen: return Color(hex: "#F4A623")
        case .bedroom: return Color(hex: "#9B59B6")
        case .bathroom: return Color(hex: "#1ABC9C")
        case .hallway: return Color(hex: "#95A5A6")
        case .diningRoom: return Color(hex: "#E67E22")
        case .office: return Color(hex: "#3498DB")
        case .storage: return Color(hex: "#7F8C8D")
        }
    }
}

// MARK: - Wall
struct Wall: Codable, Identifiable {
    var id: UUID = UUID()
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    var thickness: Double = 0.2

    var length: Double {
        let dx = endX - startX
        let dy = endY - startY
        return sqrt(dx*dx + dy*dy)
    }
}

// MARK: - Measurement
struct Measurement: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var length: Double
    var width: Double?
    var unit: MeasurementUnit = .meters
    var note: String = ""
    var createdAt: Date = Date()
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case meters = "m"
    case centimeters = "cm"
    case feet = "ft"
    case inches = "in"

    func convert(_ value: Double, to target: MeasurementUnit) -> Double {
        let inMeters: Double
        switch self {
        case .meters: inMeters = value
        case .centimeters: inMeters = value / 100
        case .feet: inMeters = value * 0.3048
        case .inches: inMeters = value * 0.0254
        }
        switch target {
        case .meters: return inMeters
        case .centimeters: return inMeters * 100
        case .feet: return inMeters / 0.3048
        case .inches: return inMeters / 0.0254
        }
    }
}

// MARK: - Furniture
struct FurnitureItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: FurnitureCategory
    var width: Double
    var depth: Double
    var height: Double
    var positionX: Double = 0
    var positionY: Double = 0
    var rotation: Double = 0
    var color: String = "#A0AEC0"
}

enum FurnitureCategory: String, Codable, CaseIterable {
    case seating = "Seating"
    case tables = "Tables"
    case sleeping = "Sleeping"
    case storage = "Storage"
    case appliances = "Appliances"
    case other = "Other"

    var icon: String {
        switch self {
        case .seating: return "chair.fill"
        case .tables: return "rectangle.on.rectangle"
        case .sleeping: return "bed.double.fill"
        case .storage: return "square.stack.3d.up.fill"
        case .appliances: return "washer.fill"
        case .other: return "cube.fill"
        }
    }

    static var presets: [FurnitureItem] {
        [
            FurnitureItem(name: "Sofa", category: .seating, width: 2.2, depth: 0.9, height: 0.85, color: "#6B7A90"),
            FurnitureItem(name: "Armchair", category: .seating, width: 0.85, depth: 0.85, height: 0.9, color: "#8D6E63"),
            FurnitureItem(name: "Dining Table", category: .tables, width: 1.6, depth: 0.9, height: 0.76, color: "#A0AEC0"),
            FurnitureItem(name: "Coffee Table", category: .tables, width: 1.2, depth: 0.6, height: 0.45, color: "#B0BEC5"),
            FurnitureItem(name: "Double Bed", category: .sleeping, width: 1.8, depth: 2.0, height: 0.5, color: "#90A4AE"),
            FurnitureItem(name: "Single Bed", category: .sleeping, width: 0.9, depth: 2.0, height: 0.5, color: "#90A4AE"),
            FurnitureItem(name: "Wardrobe", category: .storage, width: 2.0, depth: 0.6, height: 2.2, color: "#78909C"),
            FurnitureItem(name: "Bookshelf", category: .storage, width: 1.0, depth: 0.3, height: 2.0, color: "#8D6E63"),
            FurnitureItem(name: "Desk", category: .tables, width: 1.4, depth: 0.7, height: 0.76, color: "#A1887F"),
            FurnitureItem(name: "Refrigerator", category: .appliances, width: 0.6, depth: 0.65, height: 1.8, color: "#B0BEC5"),
        ]
    }
}

// MARK: - Material
struct Material: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: MaterialCategory
    var unit: String
    var pricePerUnit: Double
    var coverage: Double // area per unit
    var quantity: Double = 0
    var color: String = "#4A90D9"
}

enum MaterialCategory: String, Codable, CaseIterable {
    case flooring = "Flooring"
    case walls = "Walls"
    case ceiling = "Ceiling"
    case tiles = "Tiles"
    case paint = "Paint"
    case other = "Other"

    var icon: String {
        switch self {
        case .flooring: return "rectangle.grid.3x2"
        case .walls: return "rectangle.3.group"
        case .ceiling: return "square.fill.on.square.fill"
        case .tiles: return "square.grid.3x3.fill"
        case .paint: return "paintbrush.fill"
        case .other: return "hammer.fill"
        }
    }

    var color: Color {
        switch self {
        case .flooring: return Color(hex: "#8D6E63")
        case .walls: return Color(hex: "#5C6BC0")
        case .ceiling: return Color(hex: "#78909C")
        case .tiles: return Color(hex: "#26A69A")
        case .paint: return Color(hex: "#EC407A")
        case .other: return Color(hex: "#7E57C2")
        }
    }
}

// MARK: - Shopping Item
struct ShoppingItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var isPurchased: Bool = false
    var estimatedPrice: Double = 0
    var createdAt: Date = Date()
}

// MARK: - Task
struct RenovationTask: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date
    var isCompleted: Bool = false
    var priority: TaskPriority = .medium
    var category: TaskCategory = .other
    var createdAt: Date = Date()
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .btSuccess
        case .medium: return .btAccent
        case .high: return .btDanger
        }
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case measurement = "Measurement"
    case purchase = "Purchase"
    case installation = "Installation"
    case painting = "Painting"
    case other = "Other"

    var icon: String {
        switch self {
        case .measurement: return "ruler"
        case .purchase: return "cart"
        case .installation: return "wrench.and.screwdriver"
        case .painting: return "paintbrush"
        case .other: return "checkmark.circle"
        }
    }
}

// MARK: - Activity
struct ActivityEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var timestamp: Date = Date()
    var category: String
}

// MARK: - Apartment Types
enum ApartmentType: String, CaseIterable {
    case studio = "Studio"
    case oneBedroom = "1 Bedroom"
    case twoBedroom = "2 Bedrooms"
    case threeBedroom = "3 Bedrooms"
    case fourPlus = "4+ Bedrooms"
    case house = "House"
    case office = "Office"
    case commercial = "Commercial"
}

enum AppRequest {
    case initialize
    case handleTracking([String: Any])
    case handleNavigation([String: Any])
    case requestPermission
    case deferPermission
    case networkStatusChanged(Bool)
    case timeout
    case processValidation
    case fetchAttribution(deviceID: String)
    case fetchEndpoint(tracking: [String: Any])
    case finalizeWithEndpoint(String)
}

enum AppResponse {
    case initialized
    case trackingStored([String: String])
    case navigationStored([String: String])
    case validationCompleted(Bool)
    case attributionFetched([String: Any])
    case endpointFetched(String)
    case permissionGranted
    case permissionDenied
    case permissionDeferred
    case navigateToMain
    case navigateToWeb
    case showPermissionPrompt
    case hidePermissionPrompt
    case showOfflineView
    case hideOfflineView
    case error(Error)
}

final class RequestContext {
    var tracking: [String: String] = [:]
    var navigation: [String: String] = [:]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool = true
    var permission: PermissionData = .initial
    var isLocked: Bool = false
    var metadata: [String: Any] = [:]
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
        
        var canAsk: Bool {
            guard !isGranted && !isDenied else { return false }
            if let date = lastAsked {
                return Date().timeIntervalSince(date) / 86400 >= 3
            }
            return true
        }
        
        static var initial: PermissionData {
            PermissionData(isGranted: false, isDenied: false, lastAsked: nil)
        }
    }
    
    func isOrganic() -> Bool {
        tracking["af_status"] == "Organic"
    }
    
    func hasTracking() -> Bool {
        !tracking.isEmpty
    }
}

enum HexagonalError: Error {
    case validationFailed
    case networkError
    case invalidData
    case timeout
}

