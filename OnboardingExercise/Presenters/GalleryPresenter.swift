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
    func refreshGallery()
    func didUploadImageLink(indexPath: IndexPath)
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath)
}

/// how to present a gallery view
protocol GalleryPresenterProtocol {
    var view: GalleryPresenterDelegate? { get set }
    func viewDidLoad()
    func cellPressed(uiImage: UIImage, cellOfImage imageCell: ImageCell, indexPath: IndexPath)
    func fetchImageBy(indexPath: IndexPath, targetSize:CGSize, completion: @escaping (UIImage?) -> Void)
    func isCellLoading(indexPath: IndexPath) -> Bool
    func getUserPhotosCount() -> Int
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter: NSObject, GalleryPresenterProtocol {

    weak var view: GalleryPresenterDelegate?

    private var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    
    /// assumes not changing order of cells
    private var loadingCells: Set<Int> = []
    
    private let imageUploadOperationQueue = OperationQueue()
    
    // MARK: - Fetching Photos or from Photos
    func viewDidLoad() {
        // ? add prefetch here?
        imageUploadOperationQueue.maxConcurrentOperationCount = 1
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    print("Authorized")
                    self.authorizedFetchFromPhotosLibrary()
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
    
    private func authorizedFetchFromPhotosLibrary() {
        print("fetch from library is called")
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = .typeiTunesSynced
        self.userPhotoAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        DispatchQueue.main.async {
            self.view?.refreshGallery()
        }
    }
    
    func fetchImageBy(indexPath: IndexPath, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        if let photoAsset = userPhotoAssets?.object(at: indexPath.row) {
            PHImageManager.default().requestImage(for: photoAsset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: options) {
                (image, _) in
                guard let image = image else {return}
                completion(image)
            }
        } else {
            print("📕", "Could not get photo asset from index")
        }
    }
    
    // MARK: - Uploading Image
    
    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.jpegData(compressionQuality: 1)
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func cellPressed(uiImage: UIImage, cellOfImage imageCell: ImageCell, indexPath: IndexPath) {
        guard let base64Image = getBase64Image(image: uiImage) else { return }
        loadingCells.insert(indexPath.row)
         
        let op = ImageUploadOperation(imageUploadDelegate: self, base64Image: base64Image, indexPath: indexPath)
        op.completionBlock = { () in
            print("finished uploading image from cell: \(indexPath)")
            self.loadingCells.remove(indexPath.row)
        }
        imageUploadOperationQueue.addOperation(op)
    }
    
    // MARK: - Image loading for VC
    func isCellLoading(indexPath: IndexPath) -> Bool {
        return loadingCells.contains(indexPath.row)
    }
    
    func getUserPhotosCount() -> Int {
        return userPhotoAssets?.count ?? 0
    }
}

// MARK: - Image Upload Operation Delegate
extension GalleryPresenter: ImageUploadOperationDelegate {
    
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath) {
        self.saveLink(linkUrl: uploadURL)
        self.view?.didUploadImageLink(indexPath: indexPath)
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
