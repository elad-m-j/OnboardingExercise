//
//  ImageUploadOperation.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 29/03/2021.
// Based on: https://medium.com/swift2go/synchronysing-the-asynchronous-in-swift-3f91a32bfb1b

import Foundation

protocol ImageUploadOperationDelegate: NSObject {
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath)
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath)
}

class ImageUploadOperation: Operation {
    
    private var waitingTime = DispatchTimeInterval.seconds(1)
    private var index = IndexPath()
    private var base64Image: String = ""
    private weak var presenter: ImageUploadOperationDelegate?
    
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private var state = State.ready
    
    init(imageUploadDelegate: ImageUploadOperationDelegate, base64Image: String, indexPath: IndexPath) {
        self.index = indexPath
        self.base64Image = base64Image
        self.presenter = imageUploadDelegate
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
        
        print("'uploading' image from cell: \(index) rwt: \(waitingTime)")
        
        NetworkService.shared.uploadImageToImgur(withBase64String: base64Image) {
            [weak self] (uploadResult) in
            guard let self = self else { return }
            
            switch uploadResult {
                case .success(let uploadURL):
                    print("in success")
                    self.presenter?.onSuccessfulUpload(uploadURL: uploadURL, indexPath: self.index)
                case .failure(let networkError):
                    print("in error")
                    self.presenter?.onFailedUpload(networkError: networkError, indexPath: self.index)
            }
            
            self.willChangeValue(forKey: "isFinished")
            self.state = .finished
            self.didChangeValue(forKey: "isFinished")
        }
        
        
    }
}
