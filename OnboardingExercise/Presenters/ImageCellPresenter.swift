//
//  ImageCellPresenter.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 07/04/2021.
//

import UIKit


protocol ImageCellPresenterDelegate: NSObjectProtocol {
    func didUploadImageLink(indexPath: IndexPath)
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath)
    func startAnimatingSpinner()
    func stopAnimatingSpinner()
}

protocol ImageCellPresenterProtocol {
    var view: ImageCellPresenterDelegate? { get set }
    func shouldDisplayImage(completion: @escaping (UIImage) -> ())
    func cellPressed(indexPath: IndexPath)
}

class ImageCellPresenter: NSObject, ImageCellPresenterProtocol {
    
    let indexPath: IndexPath
    weak var view: ImageCellPresenterDelegate?
    
    
    init(indexPath: IndexPath){
        self.indexPath = indexPath
    }
    
    func shouldDisplayImage(completion: @escaping (UIImage) -> ()) {
        PhotosService.shared.fetchImageBy(indexPath: indexPath, isOriginalSize: false, completion: completion)
    }

    // MARK: - Uploading Image

    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.jpegData(compressionQuality: 1)
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func cellPressed(indexPath: IndexPath) {
        view?.startAnimatingSpinner()
        DispatchQueue.main.async {
            NetworkService.shared.addLoadingCell(index: indexPath.row)
        }
        PhotosService.shared.fetchImageBy(indexPath: indexPath, isOriginalSize: true) {
            (uiImage) in
            guard let base64Image = self.getBase64Image(image: uiImage) else { return }
            let operation = ImageUploadOperation(imageUploadDelegate: self, base64Image: base64Image, indexPath: indexPath)
            NetworkService.shared.addImageUploadOperation(operation: operation)
        }
    }
}

extension ImageCellPresenter: ImageUploadOperationDelegate {
    
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath) {
//        self.saveLink(linkUrl: uploadURL)
//        self.view?.didUploadImageLink(indexPath: indexPath)
        print("onSuccessfulUpload index: \(indexPath.row) self.index \(self.indexPath.row)")
        view!.stopAnimatingSpinner()
        
    }
    
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath) {
        self.view?.didFailWithError(error: networkError.error, additionalMessage: networkError.description ?? "", indexPath: indexPath)
    }
    
    private func saveLink(linkUrl url: String) {
        do {
            let context = LinksDataService.shared.persistentContainer.viewContext
            let imageLink = ImageLink(context: context)
            imageLink.linkURL = url
            try context.save()
        } catch  {
            print("📕", "Error saving link to context \(error)")
        }
    }
    
}
