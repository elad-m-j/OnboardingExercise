import UIKit

/// displays the links of uploaded images
class LinksViewController: UIViewController {

    @IBOutlet weak var linksTableView: UITableView!
    
    var links = [ImageLink]()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    /// load the links from CoreData
    private let linksPresenter = LinksPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        linksTableView.delegate = self
        linksTableView.dataSource = self
        linksPresenter.delegate = self
        
        linksPresenter.loadLinks(fromContext: context)
    }
}

extension LinksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        links.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath) as! LinkCell
        let imageLink = links[indexPath.row]
        cell.linkLabel.text = imageLink.linkURL
        return cell
    }

}

extension LinksViewController: UITableViewDelegate {
    
    /// opens a link in Safari browser
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedLinkURL = links[indexPath.row].linkURL,
           let url = URL(string: selectedLinkURL) {
            UIApplication.shared.open(url, options: [:])
        } else {
            print("Could not retrieve link")
        }
    }
}

extension LinksViewController: LinksViewControllerDelegate {
    
    /// displays the links retrieved by presenter
    func displayLinks(fromPresenter imageLinks: [ImageLink]) {
        links = imageLinks
        linksTableView.reloadData()
    }
    
}
