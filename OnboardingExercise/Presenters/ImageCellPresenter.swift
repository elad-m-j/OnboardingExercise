//
//  ImageCellPresenter.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 30/06/2021.
//

import UIKit

protocol ImageCellPresenterDelegate: AnyObject {
    func displayImage(uiImage: UIImage)
    func startAnimatingSpinner()
}

protocol ImageCellPresenterProtocol: AnyObject {
    var cellView: ImageCellPresenterDelegate? { get set }
    func loadCell(indexPath: IndexPath)
    func shouldDisplaySpinner(indexPath: IndexPath)
    func cellPressed(indexPath: IndexPath)
}

class ImageCellPresenter: ImageCellPresenterProtocol {

    weak var cellView: ImageCellPresenterDelegate?
    
    private var photosService: PhotosServiceProtocol
    private var networkService: NetworkServiceProtocol
    private var linksDataService: LinksDataServiceProtocol
   
    // MARK: - Fetching Photos or from Photos
    
    init(view: ImageCellPresenterDelegate?, sessionService: SessionService){
        self.cellView = view
        self.photosService = sessionService.photosService
        self.networkService = sessionService.networkService
        self.linksDataService = sessionService.linkDataService
    }
    
    func loadCell(indexPath: IndexPath) {
        photosService.fetchImageBy(indexPath: indexPath, imageSize: .min) {
            (uiImage) in
            self.cellView?.displayImage(uiImage: uiImage)
        }
    }
    
    func shouldDisplaySpinner(indexPath: IndexPath) {
        if(self.networkService.isLoadingCell(index: indexPath.row)) {
            print("\(Thread.isMainThread) \(indexPath.row): should display: true")
            self.cellView?.startAnimatingSpinner()
        }
    }
    
    func cellPressed(indexPath: IndexPath) {
        let operation = ImageUploadOperation(photosService: photosService, networkService: networkService, indexPath: indexPath)
        networkService.addImageUploadOperation(operation: operation)
        self.networkService.addLoadingCell(index: indexPath.row)
        
        DispatchQueue.main.async {
            self.cellView?.startAnimatingSpinner()
        }
    }
    
}
