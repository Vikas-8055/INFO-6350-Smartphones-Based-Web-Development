import UIKit

class DestinationsView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Destinations"
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 22)
        return label
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back to Main", for: .normal)
        return button
    }()

    private let addIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Destination ID (Int)"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addCityField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "City"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addCountryField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Country"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Destination", for: .normal)
        return b
    }()

    private let updateIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Destination ID to update"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateCityField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New City"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let updateButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Update Destination", for: .normal)
        return b
    }()

    private let deleteIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Destination ID to delete"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Destination", for: .normal)
        return b
    }()

    private let viewAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View All Destinations", for: .normal)
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
         addIdField, addCityField, addCountryField, addButton,
         updateIdField, updateCityField, updateButton,
         deleteIdField, deleteButton,
         viewAllButton, outputTextView,
         messageLabel
        ].forEach { addSubview($0) }
        
        let padding: CGFloat = 20
        let fieldHeight: CGFloat = 30

        titleLabel.frame = CGRect(x: 0, y: 40, width: frame.size.width, height: 40)
        backButton.frame = CGRect(x: padding, y: 90, width: 120, height: 40)

        addIdField.frame = CGRect(x: padding, y: 140, width: frame.size.width - 2*padding, height: fieldHeight)
        addCityField.frame = CGRect(x: padding, y: 180, width: frame.size.width - 2*padding, height: fieldHeight)
        addCountryField.frame = CGRect(x: padding, y: 220, width: frame.size.width - 2*padding, height: fieldHeight)
        addButton.frame = CGRect(x: padding, y: 260, width: frame.size.width - 2*padding, height: 40)

        updateIdField.frame = CGRect(x: padding, y: 310, width: frame.size.width - 2*padding, height: fieldHeight)
        updateCityField.frame = CGRect(x: padding, y: 350, width: frame.size.width - 2*padding, height: fieldHeight)
        updateButton.frame = CGRect(x: padding, y: 390, width: frame.size.width - 2*padding, height: 40)

        deleteIdField.frame = CGRect(x: padding, y: 440, width: frame.size.width - 2*padding, height: fieldHeight)
        deleteButton.frame = CGRect(x: padding, y: 480, width: frame.size.width - 2*padding, height: 40)

        viewAllButton.frame = CGRect(x: padding, y: 530, width: frame.size.width - 2*padding, height: 40)
        outputTextView.frame = CGRect(x: padding, y: 580, width: frame.size.width - 2*padding, height: 150)

        messageLabel.frame = CGRect(x: padding, y: 740, width: frame.size.width - 2*padding, height: 40)

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addDestination), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(updateDestination), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteDestination), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(viewAllDestinations), for: .touchUpInside)
    }

    @objc private func backTapped() {
        self.removeFromSuperview()
    }

    @objc private func addDestination() {
        clearMessage()
        guard let idString = addIdField.text, let id = Int(idString),
              let city = addCityField.text,
              let country = addCountryField.text else {
            showMessage("Invalid input for adding destination.")
            return
        }
        let newDestination = Destination(id: id, city: city, country: country)
        do {
            try DataStore.shared.addDestination(newDestination)
            showMessage("Destination added successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func updateDestination() {
        clearMessage()
        guard let idString = updateIdField.text, let id = Int(idString),
              let city = updateCityField.text else {
            showMessage("Invalid input for updating destination.")
            return
        }
        do {
            try DataStore.shared.updateDestination(id: id, newCity: city)
            showMessage("Destination updated successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func deleteDestination() {
        clearMessage()
        guard let idString = deleteIdField.text, let id = Int(idString) else {
            showMessage("Invalid input for deleting destination.")
            return
        }
        do {
            try DataStore.shared.deleteDestination(id: id)
            showMessage("Destination deleted successfully!", success: true)
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @objc private func viewAllDestinations() {
        clearMessage()
        let allDestinations = DataStore.shared.getAllDestinations()
        let displayString = allDestinations.map { dest in
            "ID: \(dest.id), City: \(dest.city), Country: \(dest.country)"
        }.joined(separator: "\n")
        outputTextView.text = displayString.isEmpty ? "No destinations found." : displayString
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
