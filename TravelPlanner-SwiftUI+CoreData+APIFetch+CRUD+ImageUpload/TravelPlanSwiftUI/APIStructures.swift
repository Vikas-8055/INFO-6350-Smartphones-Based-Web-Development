import Foundation


struct MockAPIDestination: Codable {
    let id: Int 
    let city: String
    let country: String
    let pictureURL: String
}

struct MockAPITrip: Codable {
    let id: Int
    let destinationID: Int
    let title: String
    let startDate: String
    let endDate: String
}
