import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://67ea0dbfbdcaa2b7f5bac9fc.mockapi.io/shravan/"
    
    private init() {}
    
    func fetch<T: Decodable>(endpoint: String, completion: @escaping (Result<[T], Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([T].self, from: data)
                completion(.success(decodedData))
                print("Fetching from URL: \(decodedData)")
                print("Received data: \(String(data: data, encoding: .utf8) ?? "nil")")

            } catch {
                completion(.failure(error))
                print(error)
            }
        }.resume()
    }
    
    enum NetworkError: Error {
        case invalidURL
        case noData
        case decodingError(Error)
    }
}
