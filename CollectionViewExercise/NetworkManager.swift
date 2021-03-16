import UIKit

protocol NetworkManagerDelegate {
    func didImageLinkUpload(_ networkManager: NetworkManager, imageLink: ImageLink)
    func didFailWithError(error: Error)
}

class NetworkManager: ObservableObject {
    
    private let anonymousImgurUploadURL = URL(string: "https://api.imgur.com/3/upload")
    var delegate: NetworkManagerDelegate?
     
    func getBase64Image(image: UIImage, complete: @escaping (String?) -> ()) {
        DispatchQueue.main.async {
            let imageData = image.pngData()
            let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
            complete(base64Image)
        }
    }
    
    func uploadImageToImgur(image: UIImage) {
        getBase64Image(image: image) { base64Image in
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
            request.addValue("Client-ID \(APICredentials.clientID)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"

            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"image\""
            body += "\r\n\r\n\(base64Image ?? "")\r\n"
            body += "--\(boundary)--\r\n"
            let postData = body.data(using: .utf8)

            request.httpBody = postData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("failed with error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print("server error")
                    return
                }
                if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("imgur upload results: \(dataString)")

                    let parsedResult: [String: AnyObject]
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                        if let dataJson = parsedResult["data"] as? [String: Any] {
                            print("Link is : \(dataJson["link"] as? String ?? "Link not found")")
                        }
                    } catch {
                        print("json serialization failed: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    
    func uploadImage(image: UIImage){
        print("in uploadImage")
        
        guard let imageData = image.pngData() else {
            fatalError("image could not be data coded")
        }
        ///trying postman
        postmanPost(imageData: imageData)
        return
        // request
        guard let request = getURLRequest(imageData: imageData) else {return}
        
        // session
        let session = URLSession(configuration: .default)
        let task = session.uploadTask(with: request, from: imageData) {(data, response, error) in
            if let error = error {
                print("http post request error - Data Task")
                self.delegate?.didFailWithError(error: error)
                return
            }
            print((response as! HTTPURLResponse).statusCode)
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                print("server error:")
                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: [])
                print("data json: \(String(describing: jsonData))")
                return
            }
            if let data = data {
                do {
                    let decodedJSON = try JSONSerialization.jsonObject(with: data, options: [])
                    print("decodedJSON: \(decodedJSON)")
//                    if let imageLink = self.parseJSON(data){
//                        DispatchQueue.main.async {
//                            self.delegate?.didImageLinkUpload(self, imageLink: imageLink)
//                        }
//                    }
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    private func getURLRequest(imageData: Data) -> URLRequest?{
        var request = URLRequest(url: anonymousImgurUploadURL!)
        request.setValue(String(format: "Client-ID \(APICredentials.clientID)"), forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.httpBody = getHTTPBodyForPostRequest(imageData: imageData, request: &request)
        return request
    }
    
    private func getHTTPBodyForPostRequest(imageData: Data, request: inout URLRequest) -> Data{
        
        let uuid = UUID().uuidString
        let CRLF = "\r\n"
        let fileName = uuid + ".png"
        let formName = "file"
        let type = "image/png"
        let boundary = String(format: "----iOSURLSessionBoundary.%08x%08x", arc4random(), arc4random())
        var body = Data()
        
        // file data //
        body.append(("--\(boundary)" + CRLF).data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(formName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append(("Content-Type: \(type)" + CRLF + CRLF).data(using: .utf8)!)
        body.append(imageData as Data)
        body.append(CRLF.data(using: .utf8)!)

        // footer //
        body.append(("--\(boundary)--" + CRLF).data(using: .utf8)!)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        return body
    }
    
    private func parseJSON(_ responseData: Data) -> ImageLink?{
        let decoder = JSONDecoder()
        do {
            let decodedJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
            print("decodedJSON: \(decodedJSON)")
            let decodedData = try decoder.decode(UploadResponseData.self, from: responseData)
            let uploadedImageLink = decodedData.data.link
            let imageLink = ImageLink(linkURL: uploadedImageLink)
            return imageLink
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
//    private func upload2(imageData: Data, name:String) {
//        let base64Image = imageData.base64EncodedString(options: .lineLength64Characters)
//        let url = "https://api.imgur.com/3/upload"
//        let parameters = [
//            "image": base64Image
//        ]
//        var req = URLRequest(url: URL(string: "https://api.imgur.com/3/upload")!,timeoutInterval: Double.infinity)
//        req.httpMethod="POST"
//        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
//        req.setValue(name, forHTTPHeaderField: "X-FileName")
//
//        req.httpBodyStream = InputStream(data: imageData)
//
//        let ses = URLSession.shared
//        let task = ses.uploadTask(withStreamedRequest: req as URLRequest)
//        task.resume()
//    }

    func uploadImageLocal(image: UIImage, name:String) {
        let req = NSMutableURLRequest(url: NSURL(string:"http://127.0.0.1:3001/")! as URL)
        let ses = URLSession.shared
        req.httpMethod="POST"
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue(name, forHTTPHeaderField: "X-FileName")
        let jpgData = image.jpegData(compressionQuality: 1.0)
        req.httpBodyStream = InputStream(data: jpgData!)
        let task = ses.uploadTask(withStreamedRequest: req as URLRequest)
        task.resume()
    }
    
    private func postmanPost(imageData: Data){
        let semaphore = DispatchSemaphore (value: 0)
        
        let base64Image = imageData.base64EncodedString(options: .lineLength64Characters)
//        let url = "https://api.imgur.com/3/upload"
//        let parameters = [
//            "image": base64Image
//        ]

        let parameters = [
            [
                "key": "image",
                "src": "/Users/elad.musba/Downloads/test-imgur-post.jpg",
                "type": "file"
            ]] as [[String : Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = ""
        for param in parameters {
            if param["disabled"] == nil {
                let paramName = param["key"]!
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""
                if param["contentType"] != nil {
                    body += "\r\nContent-Type: \(param["contentType"] as! String)"
                }
                let paramType = param["type"] as! String
                if paramType == "text" {
                    let paramValue = param["value"] as! String
                    body += "\r\n\r\n\(paramValue)\r\n"
                } else {
                    let paramSrc = param["src"] as! String
                    do {
                        let fileData = try NSData(contentsOfFile:paramSrc, options:[]) as Data
                        print("fileData EXISTS: \(fileData)")
                        let fileContent = String(data: fileData, encoding: .utf8)!
                        body += "; filename=\"\(paramSrc)\"\r\n"
                            + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
                    } catch  {
                        print("error making a source from data\(error)")
                    }
                }
            }
        }
        body += "--\(boundary)--\r\n";
        let postData = body.data(using: .utf8)

        var request = URLRequest(url: URL(string: "https://api.imgur.com/3/upload")!,timeoutInterval: Double.infinity)
        request.addValue("546c25a59c58ad7", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("No data from server: \(String(describing: error))")
                semaphore.signal()
                return
            }
            print("Printing data response: \(String(data: data, encoding: .utf8)!)")
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
        
}


