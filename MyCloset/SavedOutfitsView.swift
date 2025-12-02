//
//  SavedOutfitsView.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

import SwiftUI
import SwiftData

struct SavedOutfitsView: View {
    @Query private var outfits: [Outfit]
    @State private var searchText: String = ""

    private var filteredOutfits: [Outfit] {
        if searchText.isEmpty {
            return outfits
        } else {
            let lower = searchText.lowercased()
            return outfits.filter { outfit in
                outfit.title.lowercased().contains(lower) ||
                outfit.tags.joined(separator: " ").lowercased().contains(lower)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredOutfits) { outfit in
                NavigationLink {
                    DressingRoomView(existingOutfit: outfit)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(outfit.title)
                            .font(.headline)

                        if !outfit.tags.isEmpty {
                            Text(outfit.tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let date = outfit.date {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Outfits")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ClothingItem.self,
        Outfit.self,
        Trip.self,
        configurations: config
    )

    let context = container.mainContext

    // Simple preview outfits
    let o1 = Outfit(
        title: "Brunch",
        itemIDs: [],
        date: Date(),
        tags: ["casual", "daytime"]
    )
    let o2 = Outfit(
        title: "Date Night",
        itemIDs: [],
        date: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
        tags: ["night", "heels"]
    )
    context.insert(o1)
    context.insert(o2)

    return NavigationStack {
        SavedOutfitsView()
    }
    .modelContainer(container)
}
