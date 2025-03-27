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

        guard let newCity = cityTextField.text, !newCity.isEmpty,
              let destinationId = destination?.id else {
            showAlert(message: "City name cannot be empty.")
            return
        }
        
        DataManager.shared.updateDestination(id: destinationId, newCity: newCity)
        navigationController?.popViewController(animated: true)
    }
    

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
