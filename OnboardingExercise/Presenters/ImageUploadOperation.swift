//
//  ImageUploadOperation.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 29/03/2021.
// Based on: https://medium.com/swift2go/synchronysing-the-asynchronous-in-swift-3f91a32bfb1b

import Foundation
import UIKit

protocol ImageUploadOperationDelegate: AnyObject {
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath)
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath)
}
/// Uploads image from cell index (fetches original image, translates it and upload it)
/// "operations are always executed on a separate thread" https://developer.apple.com/documentation/foundation/operationqueue
class ImageUploadOperation: Operation {
    
    private var indexPath = IndexPath()
    private weak var delegate: ImageUploadOperationDelegate?
    private var photosService: PhotosServiceProtocol?
    private var networkService: NetworkServiceProtocol?
    
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private var state = State.ready
    
    init(imageUploadDelegate: ImageUploadOperationDelegate, photosService: PhotosServiceProtocol, networkService: NetworkServiceProtocol?, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.delegate = imageUploadDelegate
        self.photosService = photosService
        self.networkService = networkService
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    override func start() {
        guard !isCancelled else { return }
        state = .executing
        
        print("uploading image from cell: \(indexPath)")
        uploadDemo()
//        photosService?.fetchImageBy(indexPath: self.indexPath, isQualityImage: true) {
//            (uiImage) in
//            guard let base64Image = self.getBase64Image(image: uiImage) else { return }
//            self.networkService?.uploadImageToImgur(withBase64String: base64Image) {
//                [weak self] (uploadResult) in
//                guard let self = self else { return } // self stays until end of closure
//                // QQQ: is weak self and the statement above really necessary?
//
//                switch uploadResult {
//                    case .success(let uploadURL):
//                        self.delegate?.onSuccessfulUpload(uploadURL: uploadURL, indexPath: self.indexPath)
//                    case .failure(let networkError):
//                        self.delegate?.onFailedUpload(networkError: networkError, indexPath: self.indexPath)
//                }
//                self.networkService?.removeLoadingCell(index: self.indexPath.row)
//                self.willChangeValue(forKey: "isFinished")
//                self.state = .finished
//                self.didChangeValue(forKey: "isFinished")
//            }
//        }
    }
    
    func uploadDemo() {
        let seconds = 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.delegate?.onSuccessfulUpload(uploadURL: Constants.testURL, indexPath: self.indexPath)
            print("demo upload finished of index: \(self.indexPath.row). Not saving link")
//            self.delegate?.onFailedUpload(networkError: networkError, indexPath: self.indexPath)
            
            self.networkService?.removeLoadingCell(index: self.indexPath.row)
            self.willChangeValue(forKey: "isFinished")
            self.state = .finished
            self.didChangeValue(forKey: "isFinished")
        }
    }
}
