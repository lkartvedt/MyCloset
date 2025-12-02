//
//  ClothingThumbnailLayout.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 12/1/25.
//


import SwiftUI

// How zoomed / positioned a clothing image should be inside the 80×80 card
struct ClothingThumbnailLayout {
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    let yOffset: CGFloat
}

func thumbnailLayout(for category: ClothingCategory, subcategory: ClothingSubcategory?) -> ClothingThumbnailLayout {
    switch category {

    case .tops:
        return ClothingThumbnailLayout(
            contentWidth: 130,
            contentHeight: 230,
            yOffset: 35
        )

    case .jackets:
        return ClothingThumbnailLayout(
            contentWidth: 100,
            contentHeight: 200,
            yOffset: 30
        )

    case .bottoms:
        switch subcategory {
            case .pants:
                return ClothingThumbnailLayout(
                    contentWidth: 70,
                    contentHeight: 170,
                    yOffset: -15
                )
            case .shorts:
                return ClothingThumbnailLayout(
                    contentWidth: 140,
                    contentHeight: 240,
                    yOffset: 10
                )
            case .long_skirts:
                return ClothingThumbnailLayout(
                    contentWidth: 70,
                    contentHeight: 170,
                    yOffset: -15
                )
            case .short_skirts:
                return ClothingThumbnailLayout(
                    contentWidth: 140,
                    contentHeight: 240,
                    yOffset: 10
                )
            default:
                return ClothingThumbnailLayout(
                    contentWidth: 80,
                    contentHeight: 80,
                    yOffset: 0
                )
        }

    case .undergarments:
        switch subcategory {
            case .tights:
                return ClothingThumbnailLayout(
                    contentWidth: 60,
                    contentHeight: 160,
                    yOffset: -20
                )
            case .socks:
                return ClothingThumbnailLayout(
                    contentWidth: 140,
                    contentHeight: 240,
                    yOffset: -80
                )
            default:
                return ClothingThumbnailLayout(
                    contentWidth: 80,
                    contentHeight: 80,
                    yOffset: 0
                )
        }

    case .shoes:
        return ClothingThumbnailLayout(
            contentWidth: 200,
            contentHeight: 200,
            yOffset: -55
        )

    case .accessories:
        // Most accessories are around head/upper body
        return ClothingThumbnailLayout(
            contentWidth: 140,
            contentHeight: 200,
            yOffset: 30
        )

    case .other:
        return ClothingThumbnailLayout(
            contentWidth: 150,
            contentHeight: 260,
            yOffset: 60
        )
    }
}

// Reusable thumbnail view that respects category, subcategory, and foot style
struct ClothingThumbnailView: View {
    let item: ClothingItem
    /// Optional foot style for foot-dependent items.
    /// If nil, we default to flat → heels → generic.
    let footStyle: FootStyle?

    var body: some View {
        let layout = thumbnailLayout(for: item.category, subcategory: item.subcategory)

        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))

            if let imageName = resolvedImageName() {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: layout.contentWidth,
                        height: layout.contentHeight
                    )
                    .offset(y: layout.yOffset)
            } else {
                // Fallback "No Image"
                Text("No Image")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
    }

    private func resolvedImageName() -> String? {
        if let style = footStyle {
            // Use the current outfit's foot style
            return item.imageName(for: style) ?? item.imageName
        } else {
            // Contexts without foot style (Closet): prefer flat, then heels, then generic
            return item.imageName(for: .flat)
                ?? item.imageName(for: .heels)
                ?? item.imageName
        }
    }
}


#if DEBUG
import SwiftUI
import SwiftData

@MainActor
struct ClothingThumbnailView_Previews: PreviewProvider {

    static var previews: some View {

        // Fake items for previewing each category easily
        let sampleItems: [ClothingItem] = [
            ClothingItem(name: "Sweater", category: .tops, imageName: "green_sweater"),
            ClothingItem(name: "Jeans", category: .bottoms, subcategory: .pants, imageName: "jeans"),
            ClothingItem(name: "Black Skirt", category: .bottoms, subcategory: .short_skirts, imageName: "black_skort"),
            ClothingItem(name: "Tights", category: .undergarments, subcategory: .tights,
                         imageNameFlat: "black_sheer_flat", imageNameHeels: "black_sheer_heels",
                         supportedFootStyles: [.flat, .heels]),
            ClothingItem(name: "Socks", category: .undergarments, subcategory: .socks,
                         imageNameFlat: "black_sheer_flat", imageNameHeels: "black_sheer_heels",
                         supportedFootStyles: [.flat, .heels]),
            ClothingItem(name: "Jacket", category: .jackets, imageName: "green_sweater"),
            ClothingItem(name: "Boots", category: .shoes, imageName: "black_boots",
                         supportedFootStyles: [.heels]),
        ]

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sampleItems) { item in
                    HStack {
                        Text("\(item.name) – \(item.category.displayName)")
                            .frame(width: 180, alignment: .leading)

                        ClothingThumbnailView(item: item, footStyle: .flat)
                            .border(Color.blue.opacity(0.2))

                        // Optional: preview heel variant too
                        ClothingThumbnailView(item: item, footStyle: .heels)
                            .border(Color.red.opacity(0.2))
                    }
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif

