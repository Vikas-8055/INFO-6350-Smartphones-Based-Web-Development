import UIKit

class destinationAddViewController: UIViewController {

    @IBOutlet weak var destinationIdTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Destination"
        destinationIdTextField.keyboardType = .numberPad
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let idText = destinationIdTextField.text, let id = Int32(idText),
              let city = cityTextField.text, !city.isEmpty,
              let country = countryTextField.text, !country.isEmpty else {
            showAlert(message: "All fields are required, and ID must be a number.")
            return
        }


        let existingDestinations = DataManager.shared.fetchDestinations()
        if existingDestinations.contains(where: { $0.id == id }) {
            showAlert(message: "Destination ID is already taken. Please use a different ID.")
            return
        }

        DataManager.shared.addDestination(id: id, city: city, country: country)

        navigationController?.popViewController(animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
