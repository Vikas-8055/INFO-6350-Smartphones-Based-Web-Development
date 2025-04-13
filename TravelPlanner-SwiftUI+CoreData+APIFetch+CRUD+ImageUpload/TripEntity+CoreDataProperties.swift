import Foundation
import CoreData

extension TripEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TripEntity> {
        return NSFetchRequest<TripEntity>(entityName: "TripEntity")
    }

    @NSManaged public var id: Int32
    @NSManaged public var title: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var destination: DestinationEntity?

}

extension TripEntity: Identifiable {

}
