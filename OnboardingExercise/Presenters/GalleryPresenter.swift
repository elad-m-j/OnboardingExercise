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
}

