import SwiftUI
import SwiftData
import CoreLocation

struct OOTDView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]

    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var navigateToNewOutfit = false   // 👈 for navigation

    // Later: real location + weather integration
    @State private var locationName: String = "Current Location"
    @State private var highTemp: Int = 72
    @State private var lowTemp: Int = 60
    @State private var weatherEmoji: String = "☀️"

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d yyyy"
        return df
    }

    private var shortDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yy"
        return df
    }

    private var outfitsForDay: [Outfit] {
        outfits.filter { outfit in
            guard let d = outfit.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: selectedDate)
        }
    }

    private var defaultTitleForSelectedDate: String {
        "Outfit \(shortDateFormatter.string(from: selectedDate))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            weatherRow
            avatarAndOutfits
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("OOTD")
                    .font(.headline)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Button("Done") {
                        showingDatePicker = false
                    }
                    .padding()
                }
                .navigationTitle("Jump to Date")
            }
        }
    }

    // MARK: - Header & weather stay the same...

    private var header: some View {
        HStack {
            Button {
                changeDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(dateFormatter.string(from: selectedDate))
                .font(.headline)
                .onTapGesture {
                    showingDatePicker = true
                }

            Spacer()

            Button {
                changeDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private var weatherRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(locationName)
                    .bold()
                Spacer()
                Button("Change") {
                    // Later: present location picker / search
                }
                .font(.caption)
            }

            HStack {
                Text("\(weatherEmoji) High \(highTemp)°  Low \(lowTemp)°")
            }
        }
        .font(.subheadline)
    }

    // MARK: - Avatar + outfits + Create button

    private var avatarAndOutfits: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hidden nav link that fires when navigateToNewOutfit = true
                NavigationLink(
                    isActive: $navigateToNewOutfit
                ) {
                    DressingRoomView(
                        initialDate: selectedDate,
                        initialTitle: defaultTitleForSelectedDate,
                        dismissAfterSave: true
                    )
                } label: {
                    EmptyView()
                }
                .hidden()

                if let firstOutfit = outfitsForDay.first {
                    AvatarView(outfit: firstOutfit)
                        .frame(height: 420)
                        .frame(maxWidth: .infinity)
                }

                Text("Outfits")
                    .font(.headline)

                if outfitsForDay.isEmpty {
                    Text("No outfits saved for this date.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(outfitsForDay) { outfit in
                        NavigationLink {
                            DressingRoomView(existingOutfit: outfit)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(outfit.title)
                                        .font(.subheadline)
                                        .bold()

                                    if !outfit.tags.isEmpty {
                                        Text(outfit.tags.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("Edit")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                        }
                        .buttonStyle(.plain)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                    }
                }

                // Centered, fixed-width Create button
                HStack {
                    Spacer()
                    Button {
                        // Go to a *new* Dressing Room outfit,
                        // preconfigured for this date and with a nice default title.
                        navigateToNewOutfit = true
                    } label: {
                        Text("Create Outfit")
                            .frame(width: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func changeDay(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
