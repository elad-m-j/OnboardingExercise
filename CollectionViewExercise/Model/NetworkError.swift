//
//  NetworkError.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 24/03/2021.
//

import Foundation

class NetworkError: Error {
    
    let error: Error?
    let description: String?
    
    init(with error: Error?, description desc: String) {
        self.error = error
        self.description = desc
    }
}
