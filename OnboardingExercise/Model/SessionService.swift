//
//  SessionService.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 29/06/2021.
//

import Foundation


class SessionService {
    
    let networkService: NetworkService
    let linkDataService: LinksDataService
    let photosService: PhotosService
    
    init() {
        self.networkService = NetworkService()
        self.linkDataService = LinksDataService()
        self.photosService = PhotosService()
    }
}
