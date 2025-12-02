//
//  DressingRoomView.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

import SwiftUI
import SwiftData

struct DressingRoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClothingItem]

    @Environment(\.dismiss) private var dismiss

    @State private var workingOutfit: Outfit
    @State private var isNewOutfit: Bool
    @State private var hasInserted = false
    @State private var showSaveSheet = false
    @State private var expandedCategories: Set<ClothingCategory> = [.bottoms, .tops]


    let dismissAfterSave: Bool

    /// Order to show categories in the Dressing Room (layering order)
    private let categoryOrder: [ClothingCategory] = [
        .undergarments,
        .bottoms,
        .tops,
        .jackets,
        .accessories,
        .shoes,
        .other
    ]

    // You can tweak this list to match your actual hair assets
    private let availableHairstyles: [String] = [
        "hair_default",
        "hair_half_up_half_down",
        "hair_low_pony",
        "hair_high_pony",
        "hair_straight",
        "hair_wavy",
        "hair_two_braids",
    ]

    init(
        existingOutfit: Outfit? = nil,
        initialDate: Date? = nil,
        initialTitle: String? = nil,
        dismissAfterSave: Bool = false
    ) {
        self.dismissAfterSave = dismissAfterSave

        if let existingOutfit {
            _workingOutfit = State(initialValue: existingOutfit)
            _isNewOutfit = State(initialValue: false)
        } else {
            let title = initialTitle ?? "Outfit"
            _workingOutfit = State(initialValue: Outfit(
                title: title,
                itemIDs: [],
                date: initialDate,
                tags: [],
                tripID: nil
                // footStyle and hairAssetName use Outfit's defaults
            ))
            _isNewOutfit = State(initialValue: true)
        }
    }

    var body: some View {
        List {
            // Avatar + controls
            Section {
                VStack(spacing: 16) {
                    AvatarView(outfit: workingOutfit)
                        .frame(height: 260)

                    avatarOptionsControls
                }
                .listRowSeparator(.hidden)
            }

            // Closet, organized by category & subcategory with collapsible sections
            Section(header: Text("Closet")) {
                if items.isEmpty {
                    Text("No items yet. Add some in Closet.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(categoryOrder) { category in
                            // Filter by category *and* compatible with current foot style
                            let categoryItems = items.filter {
                                $0.category == category &&
                                $0.isCompatible(with: workingOutfit.footStyle)
                            }

                            if !categoryItems.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Category header
                                    Button {
                                        toggleCategory(category)
                                    } label: {
                                        HStack {
                                            Text(category.displayName)
                                                .font(.subheadline)
                                                .bold()
                                            Spacer()
                                            Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                                .font(.caption)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    if expandedCategories.contains(category) {
                                        let grouped = Dictionary(grouping: categoryItems) { $0.subcategory }
                                        let sortedKeys = grouped.keys.sorted { lhs, rhs in
                                            displayName(for: lhs) < displayName(for: rhs)
                                        }

                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(sortedKeys, id: \.self) { maybeSub in
                                                if let itemsForSub = grouped[maybeSub] {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(displayName(for: maybeSub))
                                                            .font(.caption)
                                                            .padding(.leading, 4)

                                                        ScrollView(.horizontal, showsIndicators: false) {
                                                            HStack(spacing: 12) {
                                                                ForEach(itemsForSub) { item in
                                                                    VStack(spacing: 4) {
                                                                        ClothingThumbnailView(item: item, footStyle: workingOutfit.footStyle)

                                                                        Text(item.name)
                                                                            .font(.caption)
                                                                            .lineLimit(1)

                                                                        if let sub = item.subcategory {
                                                                            Text(sub.displayName)
                                                                                .font(.caption2)
                                                                                .foregroundColor(.secondary)
                                                                        }
                                                                    }
                                                                    .padding(6)
                                                                    .background(
                                                                        workingOutfit.itemIDs.contains(item.id)
                                                                        ? Color.accentColor.opacity(0.15)
                                                                        : Color.clear
                                                                    )
                                                                    .cornerRadius(12)
                                                                    .onTapGesture {
                                                                        toggleItem(item)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }


            // Layering section with drag-to-reorder
            Section(header: Text("Layering (top to bottom)")) {
                if workingOutfit.itemIDs.isEmpty {
                    Text("No items selected.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(workingOutfit.itemIDs, id: \.self) { id in
                        if let item = item(for: id) {
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onMove(perform: moveLayer)
                    .onDelete(perform: removeLayer)
                }
            }

            // Save button at the bottom
            Section {
                Button("Save Outfit") {
                    showSaveSheet = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .buttonStyle(.borderedProminent)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dressing Room")
        .environment(\.editMode, .constant(.active)) // enables drag handles in layering section
        .sheet(isPresented: $showSaveSheet) {
            SaveOutfitSheet(outfit: $workingOutfit) {
                if dismissAfterSave {
                    dismiss()
                }
            }
        }
        .onChange(of: workingOutfit.itemIDs) { _ in
            // Insert brand-new outfit once it has content
            if isNewOutfit && !hasInserted && !workingOutfit.itemIDs.isEmpty {
                modelContext.insert(workingOutfit)
                hasInserted = true
            }
        }
        .onChange(of: workingOutfit.footStyle) { newStyle in
            // Drop any items that don't support the new foot style
            workingOutfit.itemIDs.removeAll { id in
                guard let item = item(for: id) else { return false }
                return !item.isCompatible(with: newStyle)
            }
        }
    }

    // MARK: - Avatar controls

    private var avatarOptionsControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Feet selection (per outfit)
            Text("Feet")
                .font(.headline)

            Picker("Feet", selection: $workingOutfit.footStyle) {
                ForEach(FootStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)

            // Hair selection (per outfit)
            Text("Hair")
                .font(.headline)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(availableHairstyles, id: \.self) { hairName in
                        let isSelected = workingOutfit.hairAssetName == hairName

                        HairSwatch(imageName: hairName, isSelected: isSelected)
                            .onTapGesture {
                                workingOutfit.hairAssetName = hairName
                            }
                    }
                }
            }
        }
        .font(.subheadline)
    }

    // MARK: - Helpers

    private func item(for id: UUID) -> ClothingItem? {
        items.first { $0.id == id }
    }

    private func toggleItem(_ item: ClothingItem) {
        if let idx = workingOutfit.itemIDs.firstIndex(of: item.id) {
            workingOutfit.itemIDs.remove(at: idx)
        } else {
            workingOutfit.itemIDs.append(item.id)
        }
    }

    private func moveLayer(from source: IndexSet, to destination: Int) {
        workingOutfit.itemIDs.move(fromOffsets: source, toOffset: destination)
    }

    private func removeLayer(at offsets: IndexSet) {
        workingOutfit.itemIDs.remove(atOffsets: offsets)
    }
    
    private func toggleCategory(_ category: ClothingCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }

    private func displayName(for subcategory: ClothingSubcategory?) -> String {
        subcategory?.displayName ?? "Other"
    }

}


// MARK: - SaveOutfitSheet (SwiftData version)

struct SaveOutfitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]

    @Binding var outfit: Outfit
    var onSave: (() -> Void)? = nil

    @State private var title: String = ""
    @State private var tagsText: String = ""
    @State private var date: Date? = nil
    @State private var selectedTripID: UUID? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Tags (comma separated)", text: $tagsText)
                }

                Section("Attach to Date") {
                    Toggle("Set specific date", isOn: Binding(
                        get: { date != nil },
                        set: { newValue in
                            if newValue {
                                date = date ?? Date()
                            } else {
                                date = nil
                            }
                        })
                    )

                    if date != nil {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { date ?? Date() },
                                set: { newValue in date = newValue }
                            ),
                            displayedComponents: .date
                        )
                    }
                }

                Section("Attach to Trip") {
                    if trips.isEmpty {
                        Text("No trips yet. Create one from Travel.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        Picker("Trip", selection: $selectedTripID) {
                            Text("None").tag(UUID?.none)
                            ForEach(trips) { trip in
                                Text(trip.name).tag(UUID?(trip.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save Outfit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { applyAndDismiss() }
                        .disabled(outfit.itemIDs.isEmpty)
                }
            }
            .onAppear {
                title = outfit.title
                tagsText = outfit.tags.joined(separator: ", ")
                date = outfit.date
                selectedTripID = outfit.tripID
            }
        }
    }

    private func applyAndDismiss() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        outfit.title = trimmedTitle.isEmpty ? "Outfit" : trimmedTitle

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        outfit.tags = tags
        outfit.date = date
        outfit.tripID = selectedTripID

        onSave?()
        dismiss()
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

    // Sample items for the preview
    let greenSweater = ClothingItem(
        name: "Green Sweater",
        category: .tops,
        imageName: "green_sweater",
        tags: ["fall", "winter"]
    )
    let jeans = ClothingItem(
        name: "Jeans 1",
        category: .bottoms,
        subcategory: .pants,
        imageName: "jeans",
        tags: ["denim"],
        supportedFootStyles: [.flat]
    )

    context.insert(greenSweater)
    context.insert(jeans)

    let outfit = Outfit(
        title: "Preview Outfit",
        itemIDs: [greenSweater.id, jeans.id],
        footStyle: .flat,
        hairAssetName: "hair_default"
    )

    context.insert(outfit)

    return NavigationStack {
        DressingRoomView(existingOutfit: outfit)
    }
    .modelContainer(container)
}


// MARK: - HairSwatch

private struct HairSwatch: View {
    let imageName: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))

            // Zoomed & cropped hair image
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 450)
                .offset(y: 100)
        }
        .frame(width: 80, height: 80)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
    }
}
