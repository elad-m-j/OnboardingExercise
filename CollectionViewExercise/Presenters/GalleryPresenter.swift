//
//  GalleryPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//
import Foundation
import Photos
import CoreData

protocol GalleryPresenterDelegate: NSObjectProtocol {
    func setAssets(photoAssets: PHFetchResult<PHAsset>)
    func didUploadImageLink(cellOfImage: ImageCell)
    func didFailWithError(error: Error?, additionalMessage: String,
                          _ cellOfImage: ImageCell)
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter {
    
    private let networkService: NetworkService
    
    weak var delegate: GalleryPresenterDelegate?
    
    init(with networkService : NetworkService){
        self.networkService = networkService
    }
    
    func fetchPhotoCollection(){
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
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
    }
    
    private func authorizedFetch(){
        let photosCollection: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: nil)
        self.delegate?.setAssets(photoAssets: photosCollection)
    }
    
    func uploadImageToImgur(withBase64StringAsImage imageString: String, cellOfImage imageCell: ImageCell) {
        networkService.uploadImageToImgur(withBase64String: imageString) { (url) in
            print("in completion")
            self.saveLink(linkUrl: url)
            self.delegate?.didUploadImageLink(cellOfImage: imageCell)
        } errorCallback: { (error, additionalMessage) in
            print("in error")
            self.delegate?.didFailWithError(error: error, additionalMessage: additionalMessage, imageCell)
        }
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
