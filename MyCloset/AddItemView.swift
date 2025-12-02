import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: ClothingCategory = .tops
    @State private var subcategory: ClothingSubcategory? = nil
    @State private var imageName: String = ""
    @State private var tagsText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Info") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }

                    Picker("Subcategory", selection: Binding(
                        get: { subcategory ?? .hats },
                        set: { newValue in subcategory = newValue }
                    )) {
                        Text("None").tag(ClothingSubcategory?.none)
                        ForEach(ClothingSubcategory.allCases) { sub in
                            Text(sub.displayName).tag(Optional(sub))
                        }
                    }
                }

                Section("Image (dev only)") {
                    TextField("Asset name (e.g. green_sweater)", text: $imageName)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                    Text("For now, this should match an Assets image set name.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Tags") {
                    TextField("Tags (comma separated)", text: $tagsText)
                }
            }
            .navigationTitle("Add Item")
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
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let item = ClothingItem(
            name: name,
            category: category,
            subcategory: subcategory,
            imageName: imageName.isEmpty ? nil : imageName,
            tags: tags
        )

        modelContext.insert(item)
        dismiss()
    }
}
