//
//  LinksPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Foundation
import CoreData

protocol LinksPresenterDelegate: NSObjectProtocol {
    func displayLinks(imageLinks: [ImageLink])
}

/// connects the LinksViewController and the LinksDataService (i.e. saving links)
class LinksPresenter {
    
    weak var delegate: LinksPresenterDelegate?
    
    func loadLinks(){
        let request: NSFetchRequest<ImageLink> = ImageLink.fetchRequest()
        do {
            let context = LinksDataService.shared.persistentContainer.viewContext
            let links = try context.fetch(request)
            delegate?.displayLinks(imageLinks: links)
        } catch {
            print("Error fetching links from database\(error)")
        }
    }
    
}
