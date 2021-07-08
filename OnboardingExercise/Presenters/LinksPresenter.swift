//
//  LinksPresenter.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 22/03/2021.
//

import Foundation
import CoreData

protocol LinksPresenterDelegate: NSObjectProtocol {
    func reloadLinks(numberOfLinks: Int)
    func openLinkInBrowser(url: URL)
}

protocol LinkPresenterProtocol {
    var view: LinksPresenterDelegate? { get set }
    func loadLinks()
    func updateNumberOfLinks()
    func linkPressed(at indexPath: IndexPath)
    func getLink(at indexPath: IndexPath) -> String?
}

/// connects the LinksViewController and the LinksDataService (i.e. saving links)
class LinksPresenter: LinkPresenterProtocol {
    
    weak var view: LinksPresenterDelegate?
    var links = [ImageLink]()
    
    private var linksDataService: LinksDataServiceProtocol
   
    // MARK: - Fetching Photos or from Photos
    
    init(view: LinksPresenterDelegate?, linksDataService: LinksDataServiceProtocol){
        self.view = view
        self.linksDataService = linksDataService
    }
    
    func loadLinks(){
        let request: NSFetchRequest<ImageLink> = ImageLink.fetchRequest()
        do {
            let context = linksDataService.persistentContainer.viewContext
            links = try context.fetch(request)
            view?.reloadLinks(numberOfLinks: links.count)
        } catch {
            print("Error fetching links from database\(error)")
        }
    }
    
    func getLink(at indexPath: IndexPath) -> String? {
        return links[indexPath.row].linkURL
    }
    
    func linkPressed(at indexPath: IndexPath) {
        if let link = links[indexPath.row].linkURL,
           let url = URL(string: link) {
            view?.openLinkInBrowser(url: url)
        } else {
            print("Could not convert link")
        }
    }
    
    func updateNumberOfLinks() {
        // Q: should this go to database?
        view?.reloadLinks(numberOfLinks: links.count)
    }
    
}
