import UIKit

class TripsView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Trips"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back to Main", for: .normal)
        return button
    }()

    private let addIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Trip ID (Int)"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addDestIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Destination ID"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addTitleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Trip Title"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addStartDateField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Start Date (yyyy-MM-dd)"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addEndDateField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "End Date (yyyy-MM-dd)"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addDescField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Description"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Trip", for: .normal)
        return b
    }()

    private let updateIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Trip ID to update"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateTitleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Title"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateEndDateField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New End Date"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateDescField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Description"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Update Trip", for: .normal)
        return b
    }()

    // --- Delete Field ---
    private let deleteIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Trip ID to delete"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Trip", for: .normal)
        return b
    }()


    private let viewAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View All Trips", for: .normal)
        return b
    }()
    private let outputTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .systemFont(ofSize: 15)
        return tv
    }()


    private let messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .systemRed
        lbl.font = .systemFont(ofSize: 14)
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white

        [titleLabel, backButton,
         addIdField, addDestIdField, addTitleField, addStartDateField, addEndDateField, addDescField, addButton,
         updateIdField, updateTitleField, updateEndDateField, updateDescField, updateButton,
         deleteIdField, deleteButton,
         viewAllButton, outputTextView,
         messageLabel
        ].forEach { addSubview($0) }

        layoutUI()
        attachActions()
    }

    private func layoutUI() {
        let padding: CGFloat = 20
        let fieldHeight: CGFloat = 30

        titleLabel.frame = CGRect(x: 0, y: 40, width: frame.size.width, height: 40)
        backButton.frame = CGRect(x: padding, y: 90, width: 120, height: 40)

        addIdField.frame = CGRect(x: padding, y: 140, width: frame.size.width - 2*padding, height: fieldHeight)
        addDestIdField.frame = CGRect(x: padding, y: 180, width: frame.size.width - 2*padding, height: fieldHeight)
        addTitleField.frame = CGRect(x: padding, y: 220, width: frame.size.width - 2*padding, height: fieldHeight)
        addStartDateField.frame = CGRect(x: padding, y: 260, width: frame.size.width - 2*padding, height: fieldHeight)
        addEndDateField.frame = CGRect(x: padding, y: 300, width: frame.size.width - 2*padding, height: fieldHeight)
        addDescField.frame = CGRect(x: padding, y: 340, width: frame.size.width - 2*padding, height: fieldHeight)
        addButton.frame = CGRect(x: padding, y: 380, width: frame.size.width - 2*padding, height: 40)

        updateIdField.frame = CGRect(x: padding, y: 430, width: frame.size.width - 2*padding, height: fieldHeight)
        updateTitleField.frame = CGRect(x: padding, y: 470, width: frame.size.width - 2*padding, height: fieldHeight)
        updateEndDateField.frame = CGRect(x: padding, y: 510, width: frame.size.width - 2*padding, height: fieldHeight)
        updateDescField.frame = CGRect(x: padding, y: 550, width: frame.size.width - 2*padding, height: fieldHeight)
        updateButton.frame = CGRect(x: padding, y: 590, width: frame.size.width - 2*padding, height: 40)

        deleteIdField.frame = CGRect(x: padding, y: 640, width: frame.size.width - 2*padding, height: fieldHeight)
        deleteButton.frame = CGRect(x: padding, y: 680, width: frame.size.width - 2*padding, height: 40)

        viewAllButton.frame = CGRect(x: padding, y: 730, width: frame.size.width - 2*padding, height: 40)
        outputTextView.frame = CGRect(x: padding, y: 780, width: frame.size.width - 2*padding, height: 130)

        messageLabel.frame = CGRect(x: padding, y: 920, width: frame.size.width - 2*padding, height: 40)
    }

    private func attachActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addTrip), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(updateTrip), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTrip), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(viewAllTrips), for: .touchUpInside)
    }

    @objc private func backTapped() {
        self.removeFromSuperview()
    }

    @objc private func addTrip() {
        clearMessage()
        guard let idStr = addIdField.text, let tripId = Int(idStr),
              let destIdStr = addDestIdField.text, let destId = Int(destIdStr),
              let title = addTitleField.text,
              let start = addStartDateField.text,
              let end = addEndDateField.text,
              let desc = addDescField.text else {
            showMessage("Invalid input for adding trip.")
            return
        }
        let newTrip = Trip(id: tripId, destination_id: destId, title: title, start_date: start, end_date: end, description: desc)
        do {
            try DataStore.shared.addTrip(newTrip)
            showMessage("Trip added successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func updateTrip() {
        clearMessage()
        guard let idStr = updateIdField.text, let tripId = Int(idStr) else {
            showMessage("Invalid Trip ID for update.")
            return
        }
        let newTitle = updateTitleField.text
        let newEndDate = updateEndDateField.text
        let newDesc = updateDescField.text

        do {
            try DataStore.shared.updateTrip(id: tripId,
                                            newTitle: newTitle,
                                            newEndDate: newEndDate,
                                            newDescription: newDesc)
            showMessage("Trip updated successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func deleteTrip() {
        clearMessage()
        guard let idStr = deleteIdField.text, let tripId = Int(idStr) else {
            showMessage("Invalid Trip ID for delete.")
            return
        }
        do {
            try DataStore.shared.deleteTrip(id: tripId)
            showMessage("Trip deleted successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func viewAllTrips() {
        clearMessage()
        let allTrips = DataStore.shared.getAllTrips()
        if allTrips.isEmpty {
            outputTextView.text = "No trips found."
            return
        }
        let displayString = allTrips.map { trip in
            """
            Trip ID: \(trip.id)
            Title: \(trip.title)
            DestinationID: \(trip.destination_id)
            Start: \(trip.start_date)
            End: \(trip.end_date)
            Description: \(trip.description)

            """
        }.joined(separator: "\n")
        outputTextView.text = displayString
    }

    private func showMessage(_ text: String, success: Bool = false) {
        messageLabel.textColor = success ? .systemGreen : .systemRed
        messageLabel.text = text
    }

    private func clearMessage() {
        messageLabel.text = ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
