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
    
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private var state = State.ready
    
    init(imageUploadDelegate: ImageUploadOperationDelegate, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.delegate = imageUploadDelegate
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
        PhotosService.shared.fetchImageBy(indexPath: self.indexPath, isQualityImage: true) {
            (uiImage) in
            guard let base64Image = self.getBase64Image(image: uiImage) else { return }
            NetworkService.shared.uploadImageToImgur(withBase64String: base64Image) {
                [weak self] (uploadResult) in
                guard let self = self else { return } // self stays until end of closure
                // is weak self and the statement above really necessary?

                switch uploadResult {
                    case .success(let uploadURL):
                        self.delegate?.onSuccessfulUpload(uploadURL: uploadURL, indexPath: self.indexPath)
                    case .failure(let networkError):
                        self.delegate?.onFailedUpload(networkError: networkError, indexPath: self.indexPath)
                }
                NetworkService.shared.removeLoadingCell(index: self.indexPath.row)
                self.willChangeValue(forKey: "isFinished")
                self.state = .finished
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }
}
