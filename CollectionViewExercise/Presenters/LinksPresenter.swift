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

protocol LinkPresenterProtocol {
    var view: LinksPresenterDelegate? { get set }
    func loadLinks()
}

/// connects the LinksViewController and the LinksDataService (i.e. saving links)
class LinksPresenter: LinkPresenterProtocol {
    
    weak var view: LinksPresenterDelegate?
    
    func loadLinks(){
        let request: NSFetchRequest<ImageLink> = ImageLink.fetchRequest()
        do {
            let context = LinksDataService.shared.persistentContainer.viewContext
            let links = try context.fetch(request)
            view?.displayLinks(imageLinks: links)
        } catch {
            print("Error fetching links from database\(error)")
        }
    }
    
}
