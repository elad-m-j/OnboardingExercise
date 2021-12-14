import UIKit

/// displays the links of uploaded images
class LinksViewController: UIViewController {

    @IBOutlet weak var linksTableView: UITableView!
    
    private var linksPresenter: LinkPresenterProtocol?
    private var numberOfLinks: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        linksTableView.delegate = self
        linksTableView.dataSource = self
        self.linksPresenter?.loadLinks()
    }
    
    func setPresenter(linksPresenter: LinkPresenterProtocol?) {
        self.linksPresenter = linksPresenter
        self.linksPresenter?.view = self
    }
    
}

// MARK: - TableView Data Source
extension LinksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfLinks
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath) as UITableViewCell
        let imageLinkURL = linksPresenter?.getLink(at: indexPath)
        cell.textLabel?.text = imageLinkURL
        return cell
    }
}

// MARK: - Open link on press
extension LinksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        linksPresenter?.linkPressed(at: indexPath)
    }
}

// MARK: - Presenter Delegate
extension LinksViewController: LinksPresenterDelegate {
        
    func reloadLinks(numberOfLinks: Int) {
        self.numberOfLinks = numberOfLinks
        linksTableView.reloadData()
    }
    
    func openLinkInBrowser(url: URL) {
        UIApplication.shared.open(url, options: [:])
    }
    
}
