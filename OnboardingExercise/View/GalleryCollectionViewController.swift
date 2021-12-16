import UIKit

/// Shows all photos in user's Photos Gallery
class GalleryCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var galleryPresenter: GalleryPresenterProtocol?
    var numberOfImages = 0
    var sessionService = SessionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.galleryPresenter =  GalleryPresenter(view: self, sessionService: sessionService)
        galleryPresenter?.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: Constants.imageCellReuseIdentifier, bundle: Bundle.main), forCellWithReuseIdentifier: Constants.imageCellReuseIdentifier)
    }
    
    /// Navigation to links screen
    @IBAction func linksPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constants.segueLinksIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == Constants.segueLinksIdentifier) {
            if let linksVC = segue.destination as? LinksViewController {
                // is VC initiated by this point?
                linksVC.setPresenter(linksPresenter: LinksPresenter(view: linksVC, linksDataService: sessionService.linkDataService))
            }
        }
    }
    
    private func printIf2(index: Int, message: String) {
        if (index == 2) {
            print("\(Thread.isMainThread) \(message)")
        }
    }
}

// MARK: - FlowLayout
extension GalleryCollectionViewController: UICollectionViewDelegateFlowLayout {

    private func getSquareWidth(_ collectionView: UICollectionView, _ flowLayout: UICollectionViewFlowLayout) -> CGSize {
        let layoutSize = collectionView.visibleSize
        let numberOfCellsInRow = layoutSize.width >= layoutSize.height ? 5 : 3
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfCellsInRow - 1))
        let squareWidth = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfCellsInRow))
        return CGSize(width: squareWidth, height: squareWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return getSquareWidth(collectionView, flowLayout)
        } else {
            print("Error: could not convert in sizeForItem")
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        }
    }
}

// MARK: - Data source
extension GalleryCollectionViewController: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfImages
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellReuseIdentifier, for: indexPath) as? ImageCellView else {
            print("Error: No cell for index: \(indexPath.row) in: cellForItemAt. Creating new ImageCell")
            return ImageCellView()
        }
        cell.load(imageCellPresenter: ImageCellPresenter(view: cell, sessionService: sessionService), indexPath: indexPath)
        return cell
    }
}

// MARK: - Clicking an image/cell
extension GalleryCollectionViewController: UICollectionViewDelegate {
        
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if let imageCell = collectionView.cellForItem(at: indexPath) as? ImageCellProtocol {
            imageCell.pressed(indexPath: indexPath)
        } else {
            print("Error: selecting a cell at \(indexPath.row)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let customCell = cell as? ImageCellView else {
            let message = "\(indexPath.row): failed casting cell"
            printIf2(index: indexPath.row, message: message)
            return
        }
        customCell.willDisplay(indexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let customCell = cell as? ImageCellView else {
            let message = "\(indexPath.row): failed casting cell"
            printIf2(index: indexPath.row, message: message)
            return
        }
        customCell.didEndDisplaying()
    }
    
}

// MARK: - Presenter Delegate
extension GalleryCollectionViewController: GalleryPresenterDelegateProtocol {

    func refreshGallery(_ totalNumberOfPhotos: Int){
        print("refreshGallery")
        numberOfImages = totalNumberOfPhotos
        collectionView.reloadData()
    }
    
    func stopAnimatingSpinnerForCell(index: Int) {
        let defaultMessage = "\(Thread.isMainThread) \(index): will stop animating"
        DispatchQueue.main.async {
            guard let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)), let customCell = cell as? ImageCellView else {
                self.printIf2(index: index, message: defaultMessage + " failed getting or casting cell")
                return
            }
            customCell.stopAnimatingSpinner()
        }
    }
    
    func showAlert(error: Error?, additionalMessage: String) {
        if self.navigationController?.topViewController == self {
            print(additionalMessage)
            print(error ?? "")
            let alert = UIAlertController(title: "Upload Failed", message: additionalMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
