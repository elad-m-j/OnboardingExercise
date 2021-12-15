//
//  ImageUploadOperation.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 29/03/2021.
// Based on: https://medium.com/swift2go/synchronysing-the-asynchronous-in-swift-3f91a32bfb1b

import Foundation
import UIKit

/// Uploads image from cell index (fetches original image, translates it and upload it)
/// "operations are always executed on a separate thread" https://developer.apple.com/documentation/foundation/operationqueue
class ImageUploadOperation: Operation {
    
    private var indexPath = IndexPath()
    private var photosService: PhotosServiceProtocol?
    private var networkService: NetworkServiceProtocol?
    
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private var state = State.ready
    
    init(photosService: PhotosServiceProtocol, networkService: NetworkServiceProtocol?, indexPath: IndexPath) {
        self.indexPath = indexPath
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
        
        print("\(indexPath.row): uploading image")
        uploadDemo()
//        realUpload()
    }
    
    private func realUpload(){
        photosService?.fetchImageBy(indexPath: self.indexPath, imageSize: .min) {
            (uiImage) in
            guard let base64Image = self.getBase64Image(image: uiImage) else { return }
            self.networkService?.uploadImageToImgur(withBase64String: base64Image) {
                [weak self] (uploadResult) in
                guard let self = self else { return } // self stays until end of closure
                // QQQ: is weak self and the statement above really necessary?

                switch uploadResult {
                    case .success(let uploadURL):            self.networkService?.onSuccessfulUpload(uploadURL: uploadURL, indexPath: self.indexPath)
                    case .failure(let networkError):
                        self.networkService?.onFailedUpload(networkError: networkError, indexPath: self.indexPath)
                }

                self.willChangeValue(forKey: "isFinished")
                self.state = .finished
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    private func uploadDemo() {
        let seconds = 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            print("\(Thread.isMainThread) \(self.indexPath.row): upload finished (demo)")
            self.networkService?.onSuccessfulUpload(uploadURL: Constants.testURL, indexPath: self.indexPath)
            self.willChangeValue(forKey: "isFinished")
            self.state = .finished
            self.didChangeValue(forKey: "isFinished")
        }
    }
}
