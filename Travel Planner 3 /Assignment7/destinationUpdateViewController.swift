import UIKit

class destinationUpdateViewController: UIViewController {

    @IBOutlet weak var cityTextField: UITextField!
    var destination: Destination?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Update Destination"
        if let destination = destination {
            cityTextField.text = destination.city
        }
    }

    @IBAction func updateButtonTapped(_ sender: UIButton) {
        guard let newCity = cityTextField.text, !newCity.isEmpty else {
            showAlert(message: "City name cannot be empty.")
            return
        }

        if let destination = destination {
            destination.city = newCity

           
            do {
                try destination.managedObjectContext?.save()
                navigationController?.popViewController(animated: true)
            } catch {
                showAlert(message: "Failed to save changes: \(error.localizedDescription)")
            }
        }
    }


    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
