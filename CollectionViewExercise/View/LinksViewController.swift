import UIKit

/// displays the links of uploaded images
class LinksViewController: UIViewController {

    @IBOutlet weak var linksTableView: UITableView!
    
    var links = [ImageLink]()
    private var linksPresenter: LinkPresenterProtocol = LinksPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        linksTableView.delegate = self
        linksTableView.dataSource = self
        linksPresenter.view = self
        
        linksPresenter.loadLinks()
    }
}

// MARK: - TableView Data Source
extension LinksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        links.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath) as UITableViewCell
        let imageLink = links[indexPath.row]
        cell.textLabel?.text = imageLink.linkURL
        return cell
    }
}

// MARK: - Open link on press
extension LinksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedLinkURL = links[indexPath.row].linkURL,
           let url = URL(string: selectedLinkURL) {
            UIApplication.shared.open(url, options: [:])
        } else {
            print("Could not retrieve link")
        }
    }
}

// MARK: - Presenter Delegate
extension LinksViewController: LinksPresenterDelegate {
    
    /// displays the links retrieved by presenter
    func displayLinks(imageLinks: [ImageLink]) {
        links = imageLinks
        linksTableView.reloadData()
    }
    
}
