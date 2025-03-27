import UIKit

class activityTableViewController: UITableViewController {
    
    var tripsWithActivities: [Trip] = []
    var activitiesByTrip: [Int: [Activity]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Activities"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
        
        
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadActivities()
        tableView.reloadData()
    }
    
    func loadActivities() {
        let allTrips = DataManager.shared.trips
        let allActivities = DataManager.shared.activities
        

        activitiesByTrip = Dictionary(grouping: allActivities, by: { $0.tripId })


        tripsWithActivities = allTrips.filter { activitiesByTrip[$0.id] != nil }
    }
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tripsWithActivities.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let trip = tripsWithActivities[section]
        return "\(trip.title) (\(trip.startDate) - \(trip.endDate))"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let trip = tripsWithActivities[section]
        return activitiesByTrip[trip.id]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        let trip = tripsWithActivities[indexPath.section]
        if let activities = activitiesByTrip[trip.id] {
            let activity = activities[indexPath.row]
            let formattedDate = formatDate(activity.date)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(activity.name), \(formattedDate) \(activity.time)"
        }
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = tripsWithActivities[indexPath.section]
        if let activities = activitiesByTrip[trip.id] {
            let selectedActivity = activities[indexPath.row]
            
            if let updateVC = storyboard?.instantiateViewController(identifier: "ActivityUpdateVC") as? activityUpdateViewController {
                updateVC.activity = selectedActivity
                navigationController?.pushViewController(updateVC, animated: true)
            }
        }
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trip = tripsWithActivities[indexPath.section]
            if var activities = activitiesByTrip[trip.id] {
                let activity = activities[indexPath.row]

              
                if DataManager.shared.deleteActivity(id: activity.id) {
                    activities.remove(at: indexPath.row)
                    activitiesByTrip[trip.id] = activities.isEmpty ? nil : activities
                    tripsWithActivities = tripsWithActivities.filter { activitiesByTrip[$0.id] != nil }
                    tableView.reloadData()
                } else {
                   
                    let alert = UIAlertController(title: "Error",
                                                  message: "Cannot delete this activity as it has already started.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

 
    func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMMM d"

        if let date = dateFormatter.date(from: dateString) {
            return outputFormatter.string(from: date) + dateSuffix(date)
        }
        return dateString
    }

    func dateSuffix(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}
