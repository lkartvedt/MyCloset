//
//  TravelView.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

// TravelView.swift
import SwiftUI
import SwiftData
import CoreLocation
import Combine
import MapKit

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
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(trips[index])
                    }
                }
            }
        }
        .navigationTitle("Travel")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTrip = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTrip) {
            AddOrEditTripView()
        }
    }
}

// MARK: - Add/Edit Trip
struct AddOrEditTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var tripToEdit: Trip?

    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

    @State private var isSaving = false
    @State private var errorMessage: String?

    // Location search
    @StateObject private var locationSearch = LocationSearchViewModel()
    @State private var selectedLocationName: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var isEditing: Bool { tripToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Name", text: $name)

                    TextField("City", text: $locationSearch.query)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Suggestions under the city field
                if !locationSearch.results.isEmpty {
                    Section("Suggestions") {
                        ForEach(locationSearch.results, id: \.self) { completion in
                            Button {
                                selectCompletion(completion)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(completion.title)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let trip = tripToEdit {
                    name = trip.name
                    startDate = trip.startDate
                    endDate = trip.endDate

                    // Pre-fill location piece if editing
                    selectedLocationName = trip.locationName
                    locationSearch.query = trip.locationName
                    if let lat = trip.latitude, let lon = trip.longitude {
                        selectedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
            }
        }
    }

    // MARK: - Selecting a suggestion

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        Task {
            do {
                let response = try await search.start()
                guard let item = response.mapItems.first,
                      let loc = item.placemark.location else {
                    await MainActor.run {
                        errorMessage = "Couldn't resolve that place."
                    }
                    return
                }

                let displayName = displayName(from: item.placemark)

                await MainActor.run {
                    selectedCoordinate = loc.coordinate
                    selectedLocationName = displayName
                    locationSearch.query = displayName
                    locationSearch.results = []
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func displayName(from placemark: MKPlacemark) -> String {
        let city = placemark.locality ?? placemark.name ?? ""
        let region = placemark.administrativeArea ?? placemark.country ?? ""
        if region.isEmpty {
            return city
        } else {
            return "\(city), \(region)"
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let coord = selectedCoordinate else {
            errorMessage = "Please pick a real place from the suggestions."
            return
        }

        let finalLocationName = selectedLocationName.isEmpty
            ? locationSearch.query
            : selectedLocationName

        if finalLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a city."
            return
        }

        if let trip = tripToEdit {
            // Edit existing
            trip.name = trimmedName
            trip.startDate = startDate
            trip.endDate = endDate
            trip.locationName = finalLocationName
            trip.latitude = coord.latitude
            trip.longitude = coord.longitude
        } else {
            // New trip
            let trip = Trip(
                name: trimmedName,
                startDate: startDate,
                endDate: endDate,
                locationName: finalLocationName,
                latitude: coord.latitude,
                longitude: coord.longitude
            )
            modelContext.insert(trip)
        }

        dismiss()
    }
}

// MARK: - Trip Detail
struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var outfits: [Outfit]
    @Query private var items: [ClothingItem]

    let trip: Trip
    
    private var tripOutfits: [Outfit] {
        outfits.filter { $0.tripID == trip.id }
    }

    private var packingItems: [ClothingItem] {
        let ids = Set(tripOutfits.flatMap { $0.itemIDs })
        return items.filter { ids.contains($0.id) }
    }

    @State private var showEdit = false

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddOrEditTripView(tripToEdit: trip)
        }
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
        name: "LA Weekend 🌴⭐️🌆🎬🌊",
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
