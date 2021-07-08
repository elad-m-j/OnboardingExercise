//
//  ImageCellPresenter.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 30/06/2021.
//

import UIKit

protocol ImageCellPresenterDelegate: AnyObject {
    func displayImage(uiImage: UIImage)
    func didUploadImageLink(indexPath: IndexPath)
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath)
    
    func startAnimatingSpinner()
    func stopAnimatingSpinner()
}

protocol ImageCellPresenterProtocol: AnyObject {
    var cellView: ImageCellPresenterDelegate? { get set }
    func viewDidLoad()
    func shouldDisplayImage(indexPath: IndexPath)
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
    
    func viewDidLoad() {
        // should this stay
    }
    
    func shouldDisplayImage(indexPath: IndexPath) {
        photosService.fetchImageBy(indexPath: indexPath, isQualityImage: false) {
            (uiImage) in
            self.cellView?.displayImage(uiImage: uiImage)
            if(self.networkService.isLoadingCell(index: indexPath.row)) {
                self.cellView?.startAnimatingSpinner()
            }
        }
    }
    
    func cellPressed(indexPath: IndexPath) {
        let operation = ImageUploadOperation(imageUploadDelegate: self, photosService: photosService, networkService: networkService, indexPath: indexPath)
        networkService.addImageUploadOperation(operation: operation)
        
        #warning("test this without main threading")
        DispatchQueue.main.async {
            self.networkService.addLoadingCell(index: indexPath.row)
            self.cellView?.startAnimatingSpinner()
        }
    }
    
}

extension ImageCellPresenter: ImageUploadOperationDelegate {
    
    func onSuccessfulUpload(uploadURL: String, indexPath: IndexPath) {
        if uploadURL == Constants.testURL {
            cellView?.didUploadImageLink(indexPath: indexPath)
            return
        }
        self.saveLink(linkUrl: uploadURL)
        cellView?.didUploadImageLink(indexPath: indexPath)
        print("onSuccessfulUpload index: \(indexPath.row)")
    }
    
    func onFailedUpload(networkError: NetworkError, indexPath: IndexPath) {
        cellView?.didFailWithError(error: networkError.error, additionalMessage: networkError.description ?? "", indexPath: indexPath)
    }
    
    private func saveLink(linkUrl url: String) {
        do {
            let context = linksDataService.persistentContainer.viewContext
            let imageLink = ImageLink(context: context)
            imageLink.linkURL = url
            try context.save()
        } catch  {
            print("📕", "Error saving link to context \(error)")
        }
    }
    
    
}

