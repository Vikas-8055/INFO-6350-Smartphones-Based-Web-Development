import Foundation

struct Trip: Decodable, Identifiable {
    let id: String
    let title: String
    let destinationID: Int  // Use Int since the JSON returns a number
    let startDate: String   // Consider using Date if you want to convert it; you'll need custom decoding
    let endDate: String
}
