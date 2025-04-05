
import Foundation

struct APIDestination: Codable {
    let id: Int32
    let city: String
    let country: String
    let pictureURL: String
}

struct APITrip: Codable {
    let id: Int32
    let title: String
    let destinationID: Int32
    let startDate: String
    let endDate: String
}
