import UIKit
import CoreData

/// make post requests of image data (as base64String) to Imgur, and returns via closure the posted image's url
class NetworkService {
    
    static let shared = NetworkService()
    
    private init(){}
    
    private let anonymousImgurUploadURL = "https://api.imgur.com/3/image"
    typealias NetworkResult = Result<String, NetworkError>
    
    
    func uploadImageToImgur(withBase64String base64Image: String, completion: @escaping (NetworkResult) -> ()) {
        if let request = getURLRequest(withImageAsString: base64Image) {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error,
                   let errorCode = response as? HTTPURLResponse {
                    completion(.failure(NetworkError(with: error, description: "Data task error with code: \(errorCode)")))
                }
                if let mimeType = response?.mimeType,
                   mimeType == "application/json",
                   let data = data,
                   let dataString = String(data: data, encoding: .utf8) {
                    completion(self.parseResultLinks(fromData: data))
                    print("---imgur upload results: \(dataString)")
                } else {
                    completion(.failure(NetworkError(with: nil, description: "error with mime type, nil data or encoding data as string")))
                }
            }.resume()
        }
    }
    
    private func parseResultLinks(fromData data: Data) -> NetworkResult {
        
        do {
            if let parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject],
               let dataJson = parsedResult["data"] as? [String: Any],
               let imageURLLink = dataJson["link"] as? String {
                return .success(imageURLLink)
            } else {
                return .failure(NetworkError(with: nil, description: "Could not parse data, image link or deleteHash"))
            }
        } catch {
            return .failure(NetworkError(with: nil, description: "json serialization failed: \(error)"))
        }
    }
    
    private func getURLRequest(withImageAsString base64Image: String) -> URLRequest? {
        guard let url = URL(string: anonymousImgurUploadURL) else { return nil}
        
        var request = URLRequest(url: url)
        let boundary = "Boundary-\(UUID().uuidString)"
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
        
    }
}


