//
//  ImageUploadOperation.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 29/03/2021.
// Based on: https://medium.com/swift2go/synchronysing-the-asynchronous-in-swift-3f91a32bfb1b

import Foundation

protocol ImageUploadOperationDelegate: AnyObject {
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath)
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath)
}

class ImageUploadOperation: Operation {
    
    private var index = IndexPath()
    private var base64Image: String = ""
    private weak var delegate: ImageUploadOperationDelegate?
    
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private var state = State.ready
    
    init(imageUploadDelegate: ImageUploadOperationDelegate, base64Image: String, indexPath: IndexPath) {
        self.index = indexPath
        self.base64Image = base64Image
        self.delegate = imageUploadDelegate
        super.init()
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
    
    override func start() {
        guard !isCancelled else { return }
        state = .executing
        
        print("uploading image from cell: \(index)")
        
        NetworkService.shared.uploadImageToImgur(withBase64String: self.base64Image) {
            [weak self] (uploadResult) in
            guard let self = self else { return } // self stays until end of closure
            // is weak self and the statement above really necessary?

            switch uploadResult {
                case .success(let uploadURL):
                    self.delegate?.onSuccessfulUpload(uploadURL: uploadURL, indexPath: self.index)
                case .failure(let networkError):
                    self.delegate?.onFailedUpload(networkError: networkError, indexPath: self.index)
            }
            NetworkService.shared.removeLoadingCell(index: self.index.row)
            self.willChangeValue(forKey: "isFinished")
            self.state = .finished
            self.didChangeValue(forKey: "isFinished")
        }
    }
}
