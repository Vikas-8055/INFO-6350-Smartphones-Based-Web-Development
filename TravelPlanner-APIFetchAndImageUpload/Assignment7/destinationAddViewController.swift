import UIKit

class destinationAddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var destinationIdTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var pictureURL: UIImageView!
    
    var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        pictureURL.layer.borderColor = UIColor.gray.cgColor
        pictureURL.layer.borderWidth = 2.0
        pictureURL.layer.cornerRadius = 8.0
        pictureURL.clipsToBounds = true
        self.title = "Add Destination"
        destinationIdTextField.keyboardType = .numberPad
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let idText = destinationIdTextField.text, let id = Int32(idText),
              let city = cityTextField.text, !city.isEmpty,
              let country = countryTextField.text, !country.isEmpty,
              pictureURL.image != nil else {
            showAlert(message: "All fields are required, and ID must be a number.")
            return
        }

        // Check for duplicate destination ID using Core Data
        let existingDestinations = DataManager.shared.fetchDestinations()
        if existingDestinations.contains(where: { $0.id == id }) {
            showAlert(message: "Destination ID is already taken. Please use a different ID.")
            return
        }
        
        // Save image data to Documents directory
        var imagePath: String?
        if let image = selectedImage {
            imagePath = saveImageToDocumentsDirectory(image: image, id: id)
        }

        // Add using Core Data
        DataManager.shared.addDestination(id: id, city: city, country: country, pictureURL: imagePath!)

        navigationController?.popViewController(animated: true)
    }
    
    func saveImageToDocumentsDirectory(image: UIImage, id: Int32) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "destination_\(id).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName // Return just the filename to store in Core Data
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            pictureURL.image = image
        }
        dismiss(animated: true, completion: nil)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
