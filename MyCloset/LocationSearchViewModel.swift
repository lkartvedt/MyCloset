import Foundation
import Combine
import MapKit

@MainActor
final class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var query: String = "" {
        didSet {
            completer.queryFragment = query
        }
    }

    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Already on main because of @MainActor, but being explicit is fine
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("LocalSearchCompleter error: \(error)")
    }
}
