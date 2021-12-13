//
//  LinksDataService.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Foundation
import CoreData

protocol LinksDataServiceProtocol: AnyObject {
    var persistentContainer: NSPersistentContainer { get }
    func saveContext ()
}

class LinksDataService: LinksDataServiceProtocol {

//    static let shared = LinksDataService()
    
//    private init(){}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
