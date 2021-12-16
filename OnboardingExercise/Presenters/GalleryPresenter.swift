//
//  GalleryPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Photos
import CoreData
import UIKit // because of the UIImage

protocol GalleryPresenterDelegateProtocol: AnyObject {
    func refreshGallery(_ totalNumberOfPhotos: Int)
    func stopAnimatingSpinnerForCell(index: Int)
    func showAlert(error: Error?, additionalMessage: String)
}

protocol GalleryPresenterProtocol: AnyObject {
    func viewDidLoad()
}

protocol GalleryPresenterNetworkProtocol: AnyObject {
    func onSuccessfulImageUpload(uploadURL: String, index: Int)
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath)
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter: GalleryPresenterProtocol {

    weak var view: GalleryPresenterDelegateProtocol?
    
    private var photosService: PhotosServiceProtocol
    private var networkService: NetworkGalleryPresenterProtocol
    private var linksDataService: LinksDataServiceProtocol
   
    // MARK: - Fetching Photos or from Photos
    
    init(view: GalleryPresenterDelegateProtocol?, sessionService: SessionService){
        self.view = view
        self.photosService = sessionService.photosService
        self.networkService = sessionService.networkService
        self.linksDataService = sessionService.linkDataService
        self.networkService.presenter = self
        view?.refreshGallery(photosService.getUserPhotosCount())
    }
    
    func viewDidLoad() {
        photosService.fetchAllUserAssets {
            DispatchQueue.main.async {
                self.view?.refreshGallery(self.photosService.getUserPhotosCount())
            }
        }
    }
}

extension GalleryPresenter: GalleryPresenterNetworkProtocol {
    
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath) {
        view?.showAlert(error: networkError.error, additionalMessage: networkError.description ?? "")
        view?.stopAnimatingSpinnerForCell(index: indexPath.row)
    }
    
    func onSuccessfulImageUpload(uploadURL: String, index: Int) {
        if uploadURL != Constants.testURL {
            self.saveLink(linkUrl: uploadURL)
        }
        view?.stopAnimatingSpinnerForCell(index: index)
    }
    
    private func saveLink(linkUrl url: String) {
        do {
            let context = linksDataService.persistentContainer.viewContext
            let imageLink = ImageLink(context: context)
            imageLink.linkURL = url
            try context.save()
        } catch  {
            print("Error saving link to context \(error)")
        }
    }
}


