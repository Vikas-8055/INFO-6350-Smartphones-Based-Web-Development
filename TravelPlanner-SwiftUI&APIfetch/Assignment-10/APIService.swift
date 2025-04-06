import SwiftUI
import Foundation
class APIService {
    
    /// Fetches destinations from the API.
    func fetchDestinations(completion: @escaping ([Destination]) -> Void) {
        guard let url = URL(string: "https://67f2b3aeec56ec1a36d3effd.mockapi.io/destinations") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching destinations: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let destinations = try JSONDecoder().decode([Destination].self, from: data)
                DispatchQueue.main.async {
                    completion(destinations)
                }
            } catch {
                print("Error decoding destination data: \(error)")
            }
        }.resume()
    }
    
    /// Fetches trips from the API.
    func fetchTrips(completion: @escaping ([Trip]) -> Void) {
        guard let url = URL(string: "https://67f2b3aeec56ec1a36d3effd.mockapi.io/trips") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching trips: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let trips = try JSONDecoder().decode([Trip].self, from: data)
                DispatchQueue.main.async {
                    completion(trips)
                }
            } catch {
                print("Error decoding trip data: \(error)")
            }
        }.resume()
    }
}
