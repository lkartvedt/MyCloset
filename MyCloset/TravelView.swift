//
//  TravelView.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

import SwiftUI
import SwiftData

struct TravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]

    @State private var showAddTrip = false

    var body: some View {
        List {
            if trips.isEmpty {
                Text("No trips yet. Add one to plan outfits and packing lists.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(trips) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(trip.name)
                                .font(.headline)
                            Text("\(trip.startDate, style: .date) – \(trip.endDate, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(trip.locationName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Travel")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTrip = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTrip) {
            AddTripView()
        }
    }
}

// MARK: - Add Trip

struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trip = Trip(
            name: name,
            startDate: startDate,
            endDate: endDate,
            locationName: location.isEmpty ? "Trip" : location
        )
        modelContext.insert(trip)
        dismiss()
    }
}

// MARK: - Trip Detail

struct TripDetailView: View {
    @Query private var allOutfits: [Outfit]
    @Query private var allItems: [ClothingItem]

    let trip: Trip

    private var tripOutfits: [Outfit] {
        allOutfits.filter { $0.tripID == trip.id }
    }

    private var packingItems: [ClothingItem] {
        let ids = Set(tripOutfits.flatMap { $0.itemIDs })
        return allItems.filter { ids.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(trip.name)
                .font(.title2)
                .bold()

            Text("\(trip.startDate, style: .date) – \(trip.endDate, style: .date)")
                .foregroundColor(.secondary)

            Text(trip.locationName)
                .foregroundColor(.secondary)

            Divider()

            Text("Outfits for this trip")
                .font(.headline)

            if tripOutfits.isEmpty {
                Text("No outfits attached to this trip yet.\nAttach outfits from the Dressing Room.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                List {
                    ForEach(tripOutfits) { outfit in
                        Text(outfit.title)
                    }
                }
                .frame(maxHeight: 200)
            }

            Divider()

            Text("Packing List")
                .font(.headline)

            if packingItems.isEmpty {
                Text("No items yet. Attach outfits with items to this trip.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                List {
                    ForEach(packingItems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Trip")
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

    // Simple preview data
    let trip = Trip(
        name: "LA Weekend",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
        locationName: "Los Angeles"
    )
    context.insert(trip)

    return NavigationStack {
        TravelView()
    }
    .modelContainer(container)
}
