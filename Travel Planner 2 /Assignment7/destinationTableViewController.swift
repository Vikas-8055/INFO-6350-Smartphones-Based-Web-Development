import UIKit

class destinationTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Destinations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DestinationCell")
        
        // Add an Edit button to toggle editing mode (shows red minus icons)
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.destinations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath)
        let destination = DataManager.shared.destinations[indexPath.row]
        cell.textLabel?.text = "\(destination.city), \(destination.country)"
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = DataManager.shared.destinations[indexPath.row]
        
        if let updateVC = storyboard?.instantiateViewController(identifier: "UpdateDestinationVC") as? destinationUpdateViewController {
            updateVC.destination = destination
            navigationController?.pushViewController(updateVC, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let destination = DataManager.shared.destinations[indexPath.row]
            if DataManager.shared.deleteDestination(id: destination.id) {
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                let alert = UIAlertController(title: "Error",
                                              message: "Cannot delete this destination as it is linked to a trip.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
    

    @IBAction func addDestination(_ sender: Any) {

    }
}
