//
//  ViewController.swift
//  WhichFlower
//
//  Created by Madhu on 23/06/20.
//  Copyright © 2020 Madhu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    
    var classificationResults : [VNClassificationObservation] = []
    var imagePicker           = UIImagePickerController()
    let wikipediaURl          = "https://en.wikipedia.org/w/api.php"
    
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label    : UILabel!
    
   
  
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        if let userPickedImage = info[.originalImage] as? UIImage
        {
            guard let convertedImage = CIImage(image : userPickedImage)
                else
            {
                    fatalError("Cannot Coverted to CI Image")
            }
            
            // if we Set This Then user Picked Image will show
           // imageView.image = userPickedImage
            detect(image:convertedImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    func detect(image : CIImage)
    {
        guard let model =  try? VNCoreMLModel(for: FlowerClassifier().model)
            else
            {
            fatalError("Cannot Import  ML Model")
            }
        let request = VNCoreMLRequest(model: model)
                        { (request, error) in
            
                            guard let classification = request.results?.first as? VNClassificationObservation
                            else
                            {
                                fatalError("Could Not Classify Image")
                            }
            
                            self.navigationItem.title = classification.identifier.capitalized
                            self.requestInfo(flowerName: classification.identifier)
                        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do
        {
            try handler.perform([request])
        }
        catch
        {
            print(error)
        }
    }
    
    
    func requestInfo(flowerName : String)
    {
        let parameters : [String:String] = [
        "format"       : "json",
        "action"       : "query",
        "prop"         : "extracts|pageimages",
        "exintro"      : "",
        "explaintext"  : "",
        "titles"       : flowerName,
        "indexpageids" : "",
        "redirects"    : "1",
        "pithumbsize"  : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess
            {
                print("We Got WikiPedia Information")
               // print(response.result)
                print(response)
                
                let flowerJSON: JSON = JSON(response.result.value!)
                
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                 
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                // Getting Web Image of Our Picked Image
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                    
                self.label.text = flowerDescription
                
                
            }
        }
        
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem)
    {
        imagePicker.sourceType    = .photoLibrary
        imagePicker.allowsEditing = true
        
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        imagePicker.delegate  = self
    }
    
    
}

