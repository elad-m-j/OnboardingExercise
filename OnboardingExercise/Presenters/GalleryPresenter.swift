//
//  GalleryPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//
import Foundation
import Photos
import CoreData
import UIKit // because of the UIImage

protocol GalleryPresenterDelegate: AnyObject {
    func refreshGallery()
    func didUploadImageLink(indexPath: IndexPath)
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath)
}

protocol GalleryPresenterProtocol: AnyObject {
    var view: GalleryPresenterDelegate? { get set }
    func viewDidLoad()
    func shouldDisplayImage(indexPath: IndexPath, completion: @escaping (UIImage) -> ())
    func cellPressed(indexPath: IndexPath)
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter: GalleryPresenterProtocol {

    weak var view: GalleryPresenterDelegate?
    
    /// assumes not changing order of cells
    private var loadingCells: Set<Int> = []
    
    private let imageUploadOperationQueue = OperationQueue()
    
    // MARK: - Fetching Photos or from Photos
    func viewDidLoad() {
        // ? add prefetch here?
        imageUploadOperationQueue.maxConcurrentOperationCount = 1
        PhotosService.shared.fetchAllUserAssets {
            DispatchQueue.main.async {
                self.view?.refreshGallery()
            }
        }
    }
    
    func shouldDisplayImage(indexPath: IndexPath, completion: @escaping (UIImage) -> ()) {
        PhotosService.shared.fetchImageBy(indexPath: indexPath, isQualityImage: false, completion: completion)
    }
    
    // MARK: - Uploading Image
    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func cellPressed(indexPath: IndexPath) {
        DispatchQueue.main.async {
            NetworkService.shared.addLoadingCell(index: indexPath.row)
        }
        PhotosService.shared.fetchImageBy(indexPath: indexPath, isQualityImage: true) {
            (uiImage) in
            guard let base64Image = self.getBase64Image(image: uiImage) else { return }
            let operation = ImageUploadOperation(imageUploadDelegate: self, base64Image: base64Image, indexPath: indexPath)
            NetworkService.shared.addImageUploadOperation(operation: operation)
        }
    }
}

extension GalleryPresenter: ImageUploadOperationDelegate {
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath) {
        self.saveLink(linkUrl: uploadURL)
        view?.didUploadImageLink(indexPath: indexPath)
        print("onSuccessfulUpload index: \(indexPath.row)")
    }
    
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath) {
        view?.didFailWithError(error: networkError.error, additionalMessage: networkError.description ?? "", indexPath: indexPath)
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

