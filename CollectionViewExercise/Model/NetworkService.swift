import UIKit
import CoreData

/// make post requests of image data (as base64String) to Imgur, and returns via closure the posted image's url
class NetworkService {
    
    private let anonymousImgurUploadURL = URL(string: "https://api.imgur.com/3/image")
    
    func uploadImageToImgur(withBase64String base64Image: String, completion: @escaping (String) -> (), errorCallback: @escaping (Error?, String) -> ()) {
        if let request = getURLRequest(withImageAsString: base64Image) {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    errorCallback(error, "Data task error")
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if !((200...299).contains(response.statusCode)){
                        errorCallback(nil, "server error \(response.statusCode)")
                        return
                    } // else continue
                } else {
                    errorCallback(nil, "Could not convert response to HTTPURLResponse")
                }
                
                if let mimeType = response?.mimeType,
                   mimeType == "application/json",
                   let data = data,
                   let dataString = String(data: data, encoding: .utf8) {
                    self.parseResultLinks(fromData: data, completion: completion)
                    print("---imgur upload results: \(dataString)")
                } else {
                    errorCallback(nil, "error with mime type, nil data or encoding data as string")
                }
            }.resume()
        }
    }
    
    private func parseResultLinks(fromData data: Data, completion: (String) -> ()) {
        let parsedResult: [String: AnyObject]
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            if let dataJson = parsedResult["data"] as? [String: Any],
               let imageURLLink = dataJson["link"] as? String {
                completion(imageURLLink)
                return
            } else {
                print( "Could not parse data, image link or deleteHash")
                return
            }
        } catch {
            print ("json serialization failed: \(error)")
            return
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


