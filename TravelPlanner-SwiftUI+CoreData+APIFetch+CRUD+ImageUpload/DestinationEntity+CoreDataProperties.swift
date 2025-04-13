import Foundation
import CoreData

extension DestinationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DestinationEntity> {
        return NSFetchRequest<DestinationEntity>(entityName: "DestinationEntity")
    }

    @NSManaged public var destinationID: Int32   // Replacing UUID with Int32 for auto-incrementing
    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var image: Data?
    @NSManaged public var trips: NSSet?

    // MARK: - Auto-increment logic for destinationID
    static func getNextDestinationID(context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<DestinationEntity> = DestinationEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "destinationID", ascending: false)]

        do {
            if let lastDestination = try context.fetch(fetchRequest).first {
                return lastDestination.destinationID + 1
            } else {
                return 1  // If no destinations, start with 1
            }
        } catch {
            print("Error fetching destinationID: \(error)")
            return 1  // Default to 1 if error occurs
        }
    }
}

// MARK: - Generated accessors for trips
extension DestinationEntity {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: TripEntity)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: TripEntity)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)
}

extension DestinationEntity: Identifiable {}
