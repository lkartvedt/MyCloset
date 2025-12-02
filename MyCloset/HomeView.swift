import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClothingItem]

    var body: some View {
        List {
            NavigationLink("OOTD") {
                OOTDView()
            }
            NavigationLink("Dressing Room") {
                DressingRoomView()
            }
            NavigationLink("Closet") {
                ClosetView()
            }
            NavigationLink("Saved Outfits") {
                SavedOutfitsView()
            }
            NavigationLink("Travel") {
                TravelView()
            }
        }
        .navigationTitle("MyCloset")
        .onAppear {
            seedDefaultClothesIfNeeded()
        }
    }

    private func seedDefaultClothesIfNeeded() {
        guard items.isEmpty else { return }
        let defaults = DefaultClothingData.makeItems()
        defaults.forEach { modelContext.insert($0) }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(
        for: [ClothingItem.self, Outfit.self, Trip.self],
        inMemory: true
    )
}
