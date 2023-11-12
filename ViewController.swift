//
//  ViewController.swift
//  WhatFlower
//
//  Created by Haldox on 11/11/2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.allowsEditing = false // set to true to allow editing
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // change to .editedImage to allow editing
        if let userPickedImage = info[.originalImage] as? UIImage {
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to CIImage")
            }
            detect(image: convertedCIImage)
            imageView.image = userPickedImage
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Flowers(configuration: MLModelConfiguration()).model) else {
            fatalError("Unable to load your model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters: [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseData { response in
            if response.data != nil {
                let flowerJSON: JSON = JSON(response.data!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                self.label.text = flowerDescription.htmlToString
            }
            
//            if (try! response.result.get().isEmpty) {
//                print("FAILURE")
//            } else {
//                print("Got the wikipedia info.")
//                print(response)
//                let flowerJSON: JSON = JSON(response)
//                let pageID = flowerJSON["query"]["pageids"][0].stringValue
//                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
//                self.label.text = flowerDescription
//            }
//            switch response.result {
//            case .success (let data) :
//                let flowerJSON: JSON = JSON(data)
//                let pageID = flowerJSON["query"]["pageids"][0].stringValue
//                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
//                self.label.text = flowerDescription
//                do {
//                    let flowerJSON: JSON = try JSON(data: data)
//                    let pageID = flowerJSON["query"]["pageids"][0].stringValue
//                    let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
//                    self.label.text = flowerDescription
//                } catch {
//                    print(error)
//                }
//                print(response)
//            case .failure :
//                print("failed")
//            }
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}


extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
