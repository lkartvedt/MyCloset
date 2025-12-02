//
//  ItemDetailView.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 12/1/25.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: ClothingItem

    @State private var tagsText: String = ""

    var body: some View {
        Form {
            Section("Preview") {
                if let name = item.imageName ?? item.imageName(for: .flat) {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 160)
                        .overlay(
                            Text("No Image")
                                .foregroundColor(.secondary)
                        )
                }
            }

            Section("Info") {
                TextField("Name", text: $item.name)

                Picker("Category", selection: $item.category) {
                    ForEach(ClothingCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }

                Picker("Subcategory", selection: Binding(
                    get: { item.subcategory ?? .hats },
                    set: { newValue in item.subcategory = newValue }
                )) {
                    Text("None").tag(ClothingSubcategory?.none)
                    ForEach(ClothingSubcategory.allCases) { sub in
                        Text(sub.displayName).tag(Optional(sub))
                    }
                }

                TextField("Asset name (dev)", text: Binding(
                    get: { item.imageName ?? "" },
                    set: { item.imageName = $0.isEmpty ? nil : $0 }
                ))
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
            }

            Section("Tags") {
                TextField("Tags (comma separated)", text: $tagsText)
            }

            Section {
                Button(role: .destructive) {
                    deleteItem()
                } label: {
                    Text("Delete Item")
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tagsText = item.tags.joined(separator: ", ")
        }
        .onDisappear {
            applyTags()
        }
    }

    private func applyTags() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        item.tags = tags
    }

    private func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }
}
