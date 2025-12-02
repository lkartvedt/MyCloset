import SwiftUI
import SwiftData

struct ClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClothingItem]

    @State private var showAddItem = false

    /// Which categories are currently expanded
    @State private var expandedCategories: Set<ClothingCategory> = []

    /// Custom layering order (not the enum's raw order)
    private let categoryOrder: [ClothingCategory] = [
        .undergarments,
        .bottoms,
        .tops,
        .jackets,
        .accessories,
        .shoes,
        .other
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(categoryOrder) { category in
                    let categoryItems = items.filter { $0.category == category }

                    if !categoryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category header with chevron
                            Button {
                                toggleCategory(category)
                            } label: {
                                HStack {
                                    Text(category.displayName)
                                        .font(.headline)
                                        .bold()
                                    Spacer()
                                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)

                            if expandedCategories.contains(category) {
                                // Group items by subcategory
                                let grouped = Dictionary(grouping: categoryItems) { $0.subcategory }
                                let sortedKeys = grouped.keys.sorted { lhs, rhs in
                                    displayName(for: lhs) < displayName(for: rhs)
                                }

                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(sortedKeys, id: \.self) { maybeSub in
                                        if let itemsForSub = grouped[maybeSub] {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(displayName(for: maybeSub))
                                                    .font(.subheadline)
                                                    .padding(.horizontal)

                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 12) {
                                                        ForEach(itemsForSub) { item in
                                                            NavigationLink {
                                                                ItemDetailView(item: item)
                                                            } label: {
                                                                itemCard(item)
                                                            }
                                                            .buttonStyle(.plain)
                                                        }
                                                    }
                                                    .padding(.horizontal)
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
            .padding(.vertical)
        }
        .navigationTitle("Closet")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
    }

    // MARK: - Helpers

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

    /// Reusable card UI for a clothing item
    private func itemCard(_ item: ClothingItem) -> some View {
        VStack(spacing: 4) {
            // Thumbnail: prefer flat, then heels, then generic imageName
            ClothingThumbnailView(item: item, footStyle: nil)

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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
