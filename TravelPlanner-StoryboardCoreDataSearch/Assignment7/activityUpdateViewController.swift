import UIKit

class activityUpdateViewController: UIViewController {

    var activity: Activity?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var locationTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Update Activity"
        setupUI()
    }

    func setupUI() {
        guard let activity = activity else { return }

        nameTextField.text = activity.name
        locationTextField.text = activity.location

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let dateStr = activity.date,
           let date = dateFormatter.date(from: dateStr) {
            datePicker.date = date
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        if let timeStr = activity.time,
           let time = timeFormatter.date(from: timeStr) {
            timePicker.date = time
        }
    }

    @IBAction func updateActivityTapped(_ sender: UIButton) {
        guard let updatedName = nameTextField.text, !updatedName.isEmpty,
              let updatedLocation = locationTextField.text, !updatedLocation.isEmpty else {
            showAlert(message: "All fields are required.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let updatedDate = dateFormatter.string(from: datePicker.date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let updatedTime = timeFormatter.string(from: timePicker.date)

        if let activity = activity {
            DataManager.shared.updateActivity(
                id: activity.id,
                newName: updatedName,
                newDate: updatedDate,
                newTime: updatedTime,
                newLocation: updatedLocation
            )
        }

        navigationController?.popViewController(animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
