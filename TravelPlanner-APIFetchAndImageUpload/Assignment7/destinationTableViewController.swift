import UIKit

class DestinationTableViewCell: UITableViewCell {
    static let identifier = "DestinationCell"
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let destinationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.addArrangedSubview(cityLabel)
        stackView.addArrangedSubview(countryLabel)
        
        contentView.addSubview(destinationImageView)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            destinationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            destinationImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            destinationImageView.widthAnchor.constraint(equalToConstant: 60),
            destinationImageView.heightAnchor.constraint(equalToConstant: 60),
            
            stackView.leadingAnchor.constraint(equalTo: destinationImageView.trailingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with destination: Destination) {
        cityLabel.text = destination.city ?? "Unknown City"
        countryLabel.text = destination.country ?? "Unknown Country"
        destinationImageView.image = UIImage(systemName: "photo")
        
        loadImage(from: destination.pictureURL)
    }
    
    private func loadImage(from urlString: String?) {
        guard let urlString = urlString else {
            destinationImageView.image = UIImage(systemName: "photo")
            return
        }
        
        // Check if it's a web URL
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            loadWebImage(urlString: urlString)
        }
        // Check if it's a local file URL (with file:// prefix)
        else if urlString.hasPrefix("file://") {
            loadLocalImage(filePath: urlString)
        }
        // Assume it's a local file path (without file:// prefix)
        else {
            loadLocalImage(filePath: urlString)
        }
    }

    private func loadWebImage(urlString: String) {
        guard let url = URL(string: urlString) else {
            destinationImageView.image = UIImage(systemName: "photo")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading web image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.destinationImageView.image = UIImage(systemName: "photo")
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.destinationImageView.image = image
                }
            }
        }.resume()
    }

    private func loadLocalImage(filePath: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filePath)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try Data(contentsOf: fileURL)
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        self?.destinationImageView.image = image
                    } else {
                        self?.destinationImageView.image = UIImage(systemName: "photo")
                    }
                }
            } catch {
                print("Error loading local image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.destinationImageView.image = UIImage(systemName: "photo")
                }
            }
        }
    }
}

class destinationTableViewController: UITableViewController {
    
    var destinations: [Destination] = []
    var filteredDestinations: [Destination] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Destinations"
        tableView.register(DestinationTableViewCell.self, forCellReuseIdentifier: DestinationTableViewCell.identifier)
        tableView.rowHeight = 80
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 92, bottom: 0, right: 0)
        
        // Search Controller setup
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by city, trip ID, or activity"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Trigger initial sync
        syncData()
    }
    
    private func syncData() {
        DataManager.shared.syncDestinations { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.destinations = DataManager.shared.fetchDestinations()
                    self?.tableView.reloadData()
                } else if let error = error {
                    print("Sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        destinations = DataManager.shared.fetchDestinations()
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredDestinations.count : destinations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DestinationTableViewCell.identifier, for: indexPath) as! DestinationTableViewCell
        let destination = isSearching ? filteredDestinations[indexPath.row] : destinations[indexPath.row]
        cell.configure(with: destination)
        return cell
    }
    
    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = isSearching ? filteredDestinations[indexPath.row] : destinations[indexPath.row]
        
        if let updateVC = storyboard?.instantiateViewController(identifier: "UpdateDestinationVC") as? destinationUpdateViewController {
            updateVC.destination = destination
            navigationController?.pushViewController(updateVC, animated: true)
        }
    }
    
    // MARK: - Deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                           forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let destination = isSearching ? filteredDestinations[indexPath.row] : destinations[indexPath.row]
            
            if DataManager.shared.deleteDestination(id: destination.id) {
                if isSearching {
                    filteredDestinations.remove(at: indexPath.row)
                    destinations = DataManager.shared.fetchDestinations()
                } else {
                    destinations.remove(at: indexPath.row)
                }
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


    // MARK: - Add Destination
    @IBAction func addDestination(_ sender: Any) {
        // Present add destination screen if needed
    }

    // MARK: - Error Alert
    func showNoResultsAlert() {
        let alert = UIAlertController(title: "No Results",
                                      message: "No matching destination, trip ID, or activity name found.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search Handling
extension destinationTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }

        let lowerQuery = query.lowercased()
        let allTrips = DataManager.shared.fetchTrips()
        let allActivities = DataManager.shared.fetchActivities()

        // Declare resultSet to collect matching destination IDs
        var resultSet = Set<Int32>()

        // 1. Match by Destination City
        for destination in destinations {
            if destination.city?.lowercased().contains(lowerQuery) == true {
                resultSet.insert(destination.id)
            }
        }

        // 2. Match by Trip ID
        if let tripId = Int32(query),
           let trip = allTrips.first(where: { $0.id == tripId }) {
            resultSet.insert(trip.destinationID)
        }

        // 3. Match by Activity Name
        for activity in allActivities {
            if activity.name?.lowercased().contains(lowerQuery) == true,
               let destinationId = activity.trip?.destination?.id {
                resultSet.insert(destinationId)
            }
        }

        // Filter Destinations
        filteredDestinations = destinations.filter { resultSet.contains($0.id) }

        if filteredDestinations.isEmpty {
            isSearching = false
            tableView.reloadData()
            showNoResultsAlert()
        } else {
            isSearching = true
            tableView.reloadData()
        }
    }
}
