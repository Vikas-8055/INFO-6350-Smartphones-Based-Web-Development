import Foundation

struct Destination: Decodable, Identifiable {
    let id: String
    let city: String
    let country: String
    let pictureURL: String?  // This property will decode from "pictureurl"
    
    enum CodingKeys: String, CodingKey {
        case id, city, country
        case pictureURL = "pictureurl" // Map JSON "pictureurl" to our property "pictureURL"
    }
}
