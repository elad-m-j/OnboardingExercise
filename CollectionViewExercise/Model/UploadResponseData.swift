import Foundation

struct UploadResponseData: Decodable {
    let data: ResponseData
}

struct ResponseData: Decodable {
    let link: String
}
