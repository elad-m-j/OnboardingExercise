//
//  GalleryPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Photos
import CoreData
import UIKit // because of the UIImage

protocol GalleryPresenterDelegate: AnyObject {
    func refreshGallery(_ totalNumberOfPhotos: Int)
}

protocol GalleryPresenterProtocol: AnyObject {
    var view: GalleryPresenterDelegate? { get set }
    func viewDidLoad()
}

/// connect between the GalleryViewController and model components: Fetching Photos, NetworkService and saving links to CoreData (LinksDataService)
class GalleryPresenter: GalleryPresenterProtocol {

    

    weak var view: GalleryPresenterDelegate?
    
    /// assumes not changing order of cells
    private var loadingCells: Set<Int> = []
    
    private var photosService: PhotosServiceProtocol
    private var networkService: NetworkServiceProtocol
    private var linksDataService: LinksDataServiceProtocol
   
    // MARK: - Fetching Photos or from Photos
    
    init(view: GalleryPresenterDelegate?, sessionService: SessionService){
        self.view = view
        self.photosService = sessionService.photosService
        self.networkService = sessionService.networkService
        self.linksDataService = sessionService.linkDataService
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


