//
//  GalleryPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Foundation

protocol GalleryCollectionViewControllerDelegate: NSObjectProtocol {
    
}

class GalleryPresenter {
    // goes deeper to model
    private let networkService: NetworkService
    
    // goes up to view
    weak var delegate: GalleryCollectionViewControllerDelegate?
    
    init(with networkService : NetworkService){
        self.networkService = networkService
    }
    
}
