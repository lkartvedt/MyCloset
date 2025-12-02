//
//  Models.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

import Foundation
import SwiftData

enum ClothingCategory: String, CaseIterable, Identifiable, Codable {
    case accessories
    case jackets
    case tops
    case bottoms
    case undergarments
    case other
    case shoes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .accessories: return "Accessories"
        case .jackets: return "Jackets"
        case .tops: return "Tops"
        case .bottoms: return "Bottoms"
        case .undergarments: return "Undergarments"
        case .other: return "Other"
        case .shoes: return "Shoes"
        }
    }
}

enum FootStyle: String, CaseIterable, Identifiable, Codable {
    case flat
    case heels

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flat: return "Flat"
        case .heels: return "Heels"
        }
    }

    var assetName: String {
        switch self {
        case .flat: return "avatar_feet_flat"
        case .heels: return "avatar_feet_heels"
        }
    }
}

enum ClothingSubcategory: String, CaseIterable, Identifiable, Codable {
    // Accessories
    case hats, jewelry, bags, belts, scarves, glasses, gloves
    // Bottoms
    case pants, shorts, short_skirts, long_skirts
    //Undergarments
    case bras, underwear, socks, tights
    // Other
    case dresses, overalls, swimsuits, robes, pajamas, sports

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var subcategory: ClothingSubcategory?

    /// Generic asset name (for tops, accessories, etc.)
    var imageName: String?

    /// Optional foot-style-specific images
    var imageNameFlat: String?
    var imageNameHeels: String?

    /// Freeform tags like "winter", "denim", "Zara"
    var tags: [String]

    /// Which foot styles this item supports.
    /// nil or empty array means "no restriction" (e.g. tops, accessories).
    var supportedFootStyles: [FootStyle]?

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        subcategory: ClothingSubcategory? = nil,
        imageName: String? = nil,
        imageNameFlat: String? = nil,
        imageNameHeels: String? = nil,
        tags: [String] = [],
        supportedFootStyles: [FootStyle]? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.imageName = imageName
        self.imageNameFlat = imageNameFlat
        self.imageNameHeels = imageNameHeels
        self.tags = tags
        self.supportedFootStyles = supportedFootStyles
    }

    // MARK: - Foot-style helpers

    func isCompatible(with footStyle: FootStyle) -> Bool {
        guard let supportedFootStyles, !supportedFootStyles.isEmpty else {
            // nil or [] = no restriction (e.g. tops, accessories)
            return true
        }
        return supportedFootStyles.contains(footStyle)
    }

    func imageName(for footStyle: FootStyle) -> String? {
        if isCompatible(with: footStyle) {
            switch footStyle {
            case .flat:
                if let flat = imageNameFlat { return flat }
            case .heels:
                if let heels = imageNameHeels { return heels }
            }
        }
        // Fallback to generic image
        return imageName
    }
}

@Model
final class Outfit {
    var id: UUID
    var title: String
    /// Ordered clothing item IDs for layering
    var itemIDs: [UUID]
    /// Optional date to show on OOTD calendar
    var date: Date?
    /// Tags for search in Saved Outfits
    var tags: [String]
    /// Optional trip ID if attached to a trip
    var tripID: UUID?
    /// Per-outfit foot style (flat or heels)
    var footStyle: FootStyle
    /// Per-outfit hair asset
    var hairAssetName: String

    init(
        id: UUID = UUID(),
        title: String,
        itemIDs: [UUID],
        date: Date? = nil,
        tags: [String] = [],
        tripID: UUID? = nil,
        footStyle: FootStyle = .flat,  // default to flat
        hairAssetName: String = "hair_default"
    ) {
        self.id = id
        self.title = title
        self.itemIDs = itemIDs
        self.date = date
        self.tags = tags
        self.tripID = tripID
        self.footStyle = footStyle
        self.hairAssetName = hairAssetName
    }
}

@Model
final class Trip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var locationName: String

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        locationName: String
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.locationName = locationName
    }
}
