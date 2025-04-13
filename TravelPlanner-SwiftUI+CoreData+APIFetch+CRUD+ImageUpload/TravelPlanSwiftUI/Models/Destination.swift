import SwiftUI

struct Destination: Identifiable, Decodable {
    let id: Int
    let city: String
    let country: String
    let pictureURL: String 
    
    static var isFetched = false
}
