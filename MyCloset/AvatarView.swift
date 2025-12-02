import SwiftUI
import SwiftData

struct AvatarView: View {
    @Query private var allItems: [ClothingItem]

    let outfit: Outfit

    var body: some View {
        ZStack {
            // 1. Body (no feet, no hair)
            Image("avatar_base")
                .resizable()
                .scaledToFit()

            // 2. Feet (flat or heels) from the outfit
            Image(outfit.footStyle.assetName)
                .resizable()
                .scaledToFit()

            // 3. Clothing items (layered)
            ForEach(outfit.itemIDs, id: \.self) { id in
                if let item = item(for: id),
                   item.isCompatible(with: outfit.footStyle),
                   let imageName = item.imageName(for: outfit.footStyle) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }
            }

            // 4. Hair (per outfit)
            Image(outfit.hairAssetName)
                .resizable()
                .scaledToFit()
        }
        .scaleEffect(1.25)
    }

    private func item(for id: UUID) -> ClothingItem? {
        allItems.first { $0.id == id }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ClothingItem.self, Outfit.self, Trip.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    let top = ClothingItem(
        name: "Green Sweater",
        category: .tops,
        imageName: "green_sweater"
    )
    context.insert(top)

    let outfit = Outfit(
        title: "Preview",
        itemIDs: [top.id],
        footStyle: .flat,
        hairAssetName: "hair_default"
    )
    context.insert(outfit)

    return AvatarView(outfit: outfit)
        .modelContainer(container)
}
