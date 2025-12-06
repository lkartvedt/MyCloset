import SwiftUI
import SwiftData
import CoreLocation
import WeatherKit


struct OOTDView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]
    @Query private var trips: [Trip]

    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var navigateToNewOutfit = false
    
    // Weather info for the current date/location
    struct WeatherInfo {
        var locationName: String
        var high: Int
        var low: Int
        var symbol: String   // TODO: real weather emoji
    }
    
    @State private var weatherInfo: WeatherInfo?
    @State private var isLoadingWeather = false
    @State private var weatherError: String?


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
    
    private var activeTrip: Trip? {
        trips.first { $0.contains(selectedDate) }
    }

    private var displayLocationName: String {
        if let trip = activeTrip {
            return trip.locationName
        } else {
            return "Current Location"  // TODO: Use actual device location here
        }
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
        .onAppear {
            loadWeather()
        }
        .onChange(of: selectedDate) { _ in
            loadWeather()
        }
        .onChange(of: trips.count) { _ in
            // if trips change (e.g., you edit dates/location), refresh
            loadWeather()
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
                Text(displayLocationName)
                    .bold()
                Spacer()
                if activeTrip != nil {
                    Text("From trip")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Button("Change") {
                    // TODO: manual override / location picker
                }
                .font(.caption)
            }

            if isLoadingWeather {
                Text("Loading weather…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let info = weatherInfo {
                Text("\(info.symbol) High \(info.high)°  Low \(info.low)°")
            } else if let error = weatherError {
                Text("Weather unavailable: \(error)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Weather not loaded.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    private func loadWeather() {
        weatherError = nil
        weatherInfo = nil

        // If this date is inside a trip with coordinates, use those
        guard let trip = activeTrip,
              let lat = trip.latitude,
              let lon = trip.longitude else {
            // TODO: fall back to device location here
            return
        }

        isLoadingWeather = true

        Task {
            do {
                let service = WeatherService.shared
                let location = CLLocation(latitude: lat, longitude: lon)

                let weather = try await service.weather(for: location)

                if let firstDay = weather.dailyForecast.forecast.first {
                    let high = Int(firstDay.highTemperature.value.rounded())
                    let low = Int(firstDay.lowTemperature.value.rounded())

                    let symbolName = firstDay.symbolName
                    let emoji = emojiForSymbol(symbolName)

                    await MainActor.run {
                        self.weatherInfo = WeatherInfo(
                            locationName: trip.locationName,
                            high: high,
                            low: low,
                            symbol: emoji
                        )
                        self.isLoadingWeather = false
                    }
                } else {
                    await MainActor.run {
                        self.weatherError = "No forecast data."
                        self.isLoadingWeather = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.weatherError = "Error: \(error.localizedDescription)"
                    self.isLoadingWeather = false
                }
            }
        }
    }


    /// Very rough mapping from WeatherKit symbol name → emoji
    private func emojiForSymbol(_ symbol: String) -> String {
        if symbol.contains("sun") && !symbol.contains("cloud") {
            return "☀️"
        } else if symbol.contains("cloud.sun") {
            return "⛅️"
        } else if symbol.contains("cloud.rain") || symbol.contains("cloud.drizzle") {
            return "🌧"
        } else if symbol.contains("cloud.snow") {
            return "❄️"
        } else if symbol.contains("cloud.bolt") {
            return "🌩️"
        } else if symbol.contains("cloud") {
            return "☁️"
        } else {
            return "🌡"
        }
    }

}
