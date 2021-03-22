//
//  LinksPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Foundation
import CoreData

protocol LinksViewControllerDelegate: NSObjectProtocol {
    func displayLinks(fromPresenter imageLinks: [ImageLink])
}

class LinksPresenter {
    
    weak var delegate: LinksViewControllerDelegate?
    
    func loadLinks(fromContext context: NSManagedObjectContext){
        let request: NSFetchRequest<ImageLink> = ImageLink.fetchRequest()
        do {
            let links = try context.fetch(request)
            delegate?.displayLinks(fromPresenter: links)
        } catch {
            print("Error fetching links from database\(error)")
        }
    }
    
}
