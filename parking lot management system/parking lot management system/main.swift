import Foundation

class Vehicle {
    let licensePlate: String
    let type: String
    let color: String?
    let owner: String?
    
    init(licensePlate: String, type: String, color: String? = nil, owner: String? = nil) {
        self.licensePlate = licensePlate
        self.type = type
        self.color = color
        self.owner = owner
    }
    
    func getInfo() -> String {
        return "Vehicle \(licensePlate) (Color: \(color ?? "Unknown"), Owner: \(owner ?? "Unknown"))"
    }
}

class ParkingSpot {
    let id: Int
    let type: String?
    let size: String
    var isOccupied: Bool = false
    var vehicle: Vehicle?
    
    init(id: Int, type: String? = nil, size: String) {
        self.id = id
        self.type = type
        self.size = size
    }
    
    func assignVehicle(_ vehicle: Vehicle) -> Bool {
        guard !isOccupied else { return false }
        self.vehicle = vehicle
        self.isOccupied = true
        print("Success: Vehicle \(vehicle.licensePlate) \(vehicle.getInfo()) parked at spot \(id).")
        return true
    }
    
    func removeVehicle() -> Bool {
        guard isOccupied else { return false }
        print("Success: Vehicle \(vehicle!.licensePlate) \(vehicle!.getInfo()) removed from spot \(id).")
        self.vehicle = nil
        self.isOccupied = false
        return true
    }
}

class ParkingLot {
    private var spots: [ParkingSpot]
    
    init(spots: [ParkingSpot]) {
        self.spots = spots
    }
    
    func addSpot(_ spot: ParkingSpot) {
        spots.append(spot)
        print("Success: Spot \(spot.id) added (Type: \(spot.type ?? "No Type Restriction"), Size: \(spot.size))")
    }
    
    func parkVehicle(_ vehicle: Vehicle) -> Bool {
        if let spot = spots.first(where: { !$0.isOccupied && ($0.type == nil || $0.type == vehicle.type) }) {
            return spot.assignVehicle(vehicle)
        }
        print("Error: No suitable spot available for \(vehicle.licensePlate)")
        return false
    }
    
    func removeVehicle(_ licensePlate: String) -> Bool {
        if let spot = spots.first(where: { $0.isOccupied && $0.vehicle?.licensePlate == licensePlate }) {
            return spot.removeVehicle()
        }
        print("Error: Vehicle with license plate \(licensePlate) not found in the lot. Removal failed.")
        return false
    }
    
    func statusReport() {
        let availableSpots = spots.filter { !$0.isOccupied }.count
        print("\n=== Parking Lot Status ===")
        print("Total Capacity: \(spots.count), Available Spots: \(availableSpots)")
        for spot in spots {
            let status = spot.isOccupied ? "Occupied by \(spot.vehicle!.getInfo())" : "Available"
            print("Spot \(spot.id) (Type: \(spot.type ?? "No Type Restriction"), Size: \(spot.size)): \(status)")
        }
        print("============================\n")
    }
}

let parkingLot = ParkingLot(spots: [
    ParkingSpot(id: 1, type: "car", size: "medium"),
    ParkingSpot(id: 2, type: "motorcycle", size: "small"),
    ParkingSpot(id: 3, type: "car", size: "large"),
    ParkingSpot(id: 4, type: "truck", size: "large"),
    ParkingSpot(id: 5, size: "medium")
])

let tesla = Vehicle(licensePlate: "TESLA123", type: "car", color: "Red", owner: "Tesla")
let bmw = Vehicle(licensePlate: "BMW789", type: "motorcycle", color: "Black", owner: "BMW")
let ford = Vehicle(licensePlate: "FORD456", type: "truck", color: "Blue", owner: "Ford")
let noSpotVehicle = Vehicle(licensePlate: "NO_SPOT", type: "bus")

let teslaParked = parkingLot.parkVehicle(tesla)
let bmwParked = parkingLot.parkVehicle(bmw)
let fordParked = parkingLot.parkVehicle(ford)
parkingLot.statusReport()

let bmwRemoved = parkingLot.removeVehicle("BMW789")
let nonexistentRemoved = parkingLot.removeVehicle("NONEXISTENT")
let noSpotParked = parkingLot.parkVehicle(noSpotVehicle)
parkingLot.statusReport()
