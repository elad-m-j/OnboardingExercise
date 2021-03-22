import UIKit
import CoreData

protocol NetworkServiceDelegate {
    func didUploadImageLink(_ networkManager: NetworkService, cellOfImage: ImageCell)
    func didFailWithError(error: Error?, additionalMessage: String,
                          _ cellOfImage: ImageCell)
}

class NetworkService: ObservableObject {
    
    private let anonymousImgurUploadURL = URL(string: "https://api.imgur.com/3/image")
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var delegate: NetworkServiceDelegate?
     
    func testDataModel(_ string: String){
        let imageLinkDataObject = ImageLink(context: self.context)
        imageLinkDataObject.linkURL = string
        imageLinkDataObject.deleteHash = "Whatever"
        self.saveLink()
    }
    
    func getBase64Image(image: UIImage) -> String? {
        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func uploadImageToImgur(withUIImage image: UIImage, cellOfImage imageCell: ImageCell) {
        if let base64Image = getBase64Image(image: image),
           let request = getURLRequest(withImageAsString: base64Image) {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.delegate?.didFailWithError(error: error, additionalMessage: "Data task error", imageCell)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if !((200...299).contains(response.statusCode)){
                        self.delegate?.didFailWithError(error: nil, additionalMessage: "server error \(response.statusCode)", imageCell)
                        return
                    } // else continue
                } else {
                    self.delegate?.didFailWithError(error: nil, additionalMessage: "Could not convert response to HTTPURLResponse", imageCell)
                }
                
                if let mimeType = response?.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("---imgur upload results: \(dataString)")
                    if let parsedImageLink = self.parseResultLinks(fromData: data){
                        self.saveLink()
                        self.delegate?.didUploadImageLink(self,
                                                        cellOfImage: imageCell)
                    } else {
                        self.delegate?.didFailWithError(error: nil, additionalMessage: "Failed parsing data, link or delete hash", imageCell)
                    }
                } else {
                    self.delegate?.didFailWithError(error: nil, additionalMessage: "error with mime type, nil data or encoding data as string", imageCell)
                }
            }.resume()
        }
    }
    
    private func saveLink() {
        do {
            try self.context.save()
        } catch  {
            print("Error saving link to context \(error)")
        }
    }
    
    private func parseResultLinks(fromData data: Data) -> ImageLink? {
        let parsedResult: [String: AnyObject]
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            if let dataJson = parsedResult["data"] as? [String: Any],
               let imageURLLink = dataJson["link"] as? String,
               let deleteHash = dataJson["deletehash"] as? String {
                let imageLinkDataObject = ImageLink(context: self.context)
                imageLinkDataObject.linkURL = imageURLLink
                imageLinkDataObject.deleteHash = deleteHash
                return imageLinkDataObject
            } else {
                print( "Could not parse data, image link or deleteHash")
                return nil
            }
        } catch {
            print ("json serialization failed: \(error)")
            return nil
        }
    }
    
    private func getURLRequest(withImageAsString base64Image: String?) -> URLRequest? {
        if let base64Image = base64Image {
            
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: anonymousImgurUploadURL!)
            request.addValue("Client-ID \(APICredentials.clientID)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"image\""
            body += "\r\n\r\n\(base64Image)\r\n"
            body += "--\(boundary)--\r\n"
            let postData = body.data(using: .utf8)
            request.httpBody = postData
            return request
        } else {
            print("Error converting image to base64")
            return nil
        }
    }
}


