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

protocol GalleryPresenterDelegate: NSObjectProtocol {
    func setAssets(photoAssets: PHFetchResult<PHAsset>)
    func didUploadImageLink(indexPath: IndexPath)
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath)
}

protocol GalleryPresenterProtocol {
    var view: GalleryPresenterDelegate? { get set }
    func viewDidLoad()
    func cellPressed(uiImage: UIImage, cellOfImage imageCell: ImageCell, indexPath: IndexPath)
    func fetchImageFrom(asset: PHAsset, targetSize:CGSize, completion: @escaping (UIImage?) -> Void)
    func isCellLoading(indexPath: IndexPath) -> Bool
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter: NSObject, GalleryPresenterProtocol {

    weak var view: GalleryPresenterDelegate?
    
    /// assumes not changing order of cells
    private var loadingCells: Set<Int> = []
    
    private let operationQueue = OperationQueue()
    
    // MARK: - Fetching Photos or from Photos
    func viewDidLoad(){
        // add prefetch here?
        operationQueue.maxConcurrentOperationCount = 1
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    print("Authorized")
                    self.authorizedFetch()
                case .denied, .restricted:
                    print("Not allowed")
                case .notDetermined:
                    print("Not determined yet")
                case .limited:
                    print("Limited access")
                @unknown default:
                    print("default case in permissions")
            }
        }
    }
    
    private func authorizedFetch(){
        print("fetch is called")
        let photosCollection: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: nil)
        DispatchQueue.main.async {
            self.view?.setAssets(photoAssets: photosCollection)
        }
    }
    
    func fetchImageFrom(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFit,
                                              options: options) {
            (image, _) in
            guard let image = image else {return}
            completion(image)
        }
    }
    
    // MARK: - Uploading Image
    
    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.jpegData(compressionQuality: 0.75) // so it is quicker
//        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func cellPressed(uiImage: UIImage, cellOfImage imageCell: ImageCell, indexPath: IndexPath){
        guard let base64Image = getBase64Image(image: uiImage) else { return }
        loadingCells.insert(indexPath.row)
         
        let op = ImageUploadOperation(imageUploadDelegate: self, base64Image: base64Image, indexPath: indexPath)
        op.completionBlock = { () in
            print("finished uploading image from cell: \(indexPath.row)")
            self.loadingCells.remove(indexPath.row)
        }
        operationQueue.addOperation(op)
    }
    
    // MARK: - Image loading for VC
    func isCellLoading(indexPath: IndexPath) -> Bool {
        return loadingCells.contains(indexPath.row)
    }
}

// MARK: - Image Upload Operation Delegate
extension GalleryPresenter: ImageUploadOperationDelegate {
    
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath) {
        self.saveLink(linkUrl: uploadURL)
        self.view?.didUploadImageLink(indexPath: indexPath)
    }
    
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath){
        self.view?.didFailWithError(error: networkError.error, additionalMessage: networkError.description ?? "", indexPath: indexPath)
    }
    
    private func saveLink(linkUrl url: String) {
        do {
            let context = LinksDataService.shared.persistentContainer.viewContext
            let imageLink = ImageLink(context: context)
            imageLink.linkURL = url
            try context.save()
        } catch  {
            print("Error saving link to context \(error)")
        }
    }
}
