import SwiftUI

struct Trip: Identifiable, Decodable {
    let id: Int
    let destinationID: Int 
    let startDate: String
    let endDate: String
    var title: String
    static var isFetched = false
}
