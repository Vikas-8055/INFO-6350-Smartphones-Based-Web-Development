import UIKit

class destinationUpdateViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    var destination: Destination?
    private var selectedImage: UIImage?
    private var imageLoadingTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Update Destination"
        
        if let destination = destination {
            cityTextField.text = destination.city
            loadImage(from: destination.pictureURL)
        }
        
        // Add border and rounded corners to image view
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageLoadingTask?.cancel()
    }

    private func loadImage(from urlString: String?) {
        guard let urlString = urlString else {
            setPlaceholderImage()
            return
        }

        // Check if it's a web URL
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            loadWebImage(urlString: urlString)
        }
        // Otherwise treat as local file path
        else {
            loadLocalImage(filePath: urlString)
        }
    }

    private func loadWebImage(urlString: String) {
        guard let url = URL(string: urlString) else {
            setPlaceholderImage()
            return
        }

        showLoadingIndicator()

        imageLoadingTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()

                if let error = error {
                    print("Error loading web image: \(error.localizedDescription)")
                    self?.setPlaceholderImage()
                    return
                }

                guard let data = data, let image = UIImage(data: data) else {
                    self?.setPlaceholderImage()
                    return
                }

                self?.imageView.image = image
            }
        }
        imageLoadingTask?.resume()
    }

    private func loadLocalImage(filePath: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filePath)
        
        showLoadingIndicator()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try Data(contentsOf: fileURL)
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    if let image = UIImage(data: data) {
                        self?.imageView.image = image
                    } else {
                        self?.setPlaceholderImage()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    print("Error loading local image: \(error.localizedDescription)")
                    self?.setPlaceholderImage()
                }
            }
        }
    }

    private func showLoadingIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.tag = 999
        activityIndicator.center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        activityIndicator.startAnimating()
        imageView.addSubview(activityIndicator)
    }

    private func hideLoadingIndicator() {
        imageView.subviews.forEach { view in
            if view.tag == 999 {
                view.removeFromSuperview()
            }
        }
    }

    private func setPlaceholderImage() {
        imageView.image = UIImage(systemName: "photo")
    }

    @IBAction func updateButtonTapped(_ sender: UIButton) {
        guard let newCity = cityTextField.text, !newCity.isEmpty else {
            showAlert(message: "City name cannot be empty.")
            return
        }
        
        // If no new image selected but existing image exists, keep the old URL
        var newPictureURL = destination?.pictureURL
        
        // If there is a new image selected, save it
        if let image = selectedImage {
            // First delete the old image if it exists
            if let oldImagePath = destination?.pictureURL {
                deleteImage(at: oldImagePath)
            }
            
            // Save the new image
            newPictureURL = saveImageToDocumentsDirectory(image: image, id: destination?.id ?? 0)
        }
        
        updateDestination(city: newCity, pictureURL: newPictureURL)
    }
    
    private func saveImageToDocumentsDirectory(image: UIImage, id: Int32) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "destination_\(id).jpg" // Use the destination ID as filename
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName // Return just the filename to store in Core Data
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func deleteImage(at path: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Error deleting image: \(error.localizedDescription)")
        }
    }
    
    private func updateDestination(city: String, pictureURL: String?) {
        guard let destination = destination else { return }
        
        destination.city = city
        destination.pictureURL = pictureURL
        
        do {
            try destination.managedObjectContext?.save()
            navigationController?.popViewController(animated: true)
        } catch {
            showAlert(message: "Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Image Picker
    @IBAction func chooseImageTapped(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage {
            self.selectedImage = selectedImage
            imageView.image = selectedImage
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    private func showAlert(message: String) {
        guard presentedViewController == nil else { return }
        
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
