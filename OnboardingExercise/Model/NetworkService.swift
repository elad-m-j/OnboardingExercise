import UIKit
import CoreData

struct NetworkError: Error {
    let error: Error?
    let description: String?
}
/// make post requests of image data, manages operation queue and which table cells are loading
class NetworkService {
    
    static let shared = NetworkService()
    
    private init(){
        imageUploadOperationQueue.maxConcurrentOperationCount = 1
    }
    
    private let anonymousImgurUploadURL = "https://api.imgur.com/3/image"
    typealias NetworkResult = Result<String, NetworkError>
    
    private var loadingCells: Set<Int> = []
    
    // MARK: - upload operation queue
    private let imageUploadOperationQueue = OperationQueue()
    
    func addImageUploadOperation(operation: ImageUploadOperation){
        imageUploadOperationQueue.addOperation(operation)
    }
    
    // MARK: - Loading cells CRUD
    func addLoadingCell(index: Int){
        loadingCells.insert(index)
    }
    
    func isLoadingCell(index: Int) -> Bool {
        return loadingCells.contains(index)
    }
    
    func removeLoadingCell(index: Int) {
        loadingCells.remove(index)
    }
    
    func uploadImageToImgur(withBase64String base64Image: String, completion: @escaping (NetworkResult) -> ()) {
        if let request = getURLRequest(withImageAsString: base64Image) {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error,
                   let errorCode = response as? HTTPURLResponse {
                    completion(.failure(NetworkError(error: error, description: "Data task error with code: \(errorCode)")))
                }
                if let data = data {
                    completion(self.parseResultLinks(fromData: data))
                } else {
                    completion(.failure(NetworkError(error: nil, description: "error with mime type, nil data or encoding data as string")))
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
                return .failure(NetworkError(error: nil, description: "Could not parse data, image link or deleteHash"))
            }
        } catch {
            return .failure(NetworkError(error: nil, description: "json serialization failed: \(error)"))
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


