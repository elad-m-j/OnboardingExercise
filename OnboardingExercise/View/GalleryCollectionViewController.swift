import UIKit

/// Shows all photos in user's Photos Gallery
class GalleryCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let defaultImageSize = CGSize(width: 300, height: 300)
    
    private var galleryPresenter: GalleryPresenterProtocol = GalleryPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        galleryPresenter.view = self
        galleryPresenter.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    /// Navigation to links screen
    @IBAction func linksPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constants.segueLinksIdentifier, sender: self)
    }
}

// MARK: - Images Per Row Constraint with  FlowLayout
extension GalleryCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            let layoutSize = collectionView.visibleSize
            let numberOfCellsInRow = layoutSize.width >= layoutSize.height ? 5 : 3
            let totalSpace = flowLayout.sectionInset.left
                + flowLayout.sectionInset.right
                + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfCellsInRow - 1))
            let squareWidth = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfCellsInRow))
            return CGSize(width: squareWidth, height: squareWidth)
        } else {
            print("📕", "could not convert in sizeForItem")
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        }
    }
}

// MARK: - Data source
extension GalleryCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryPresenter.getUserPhotosCount()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellReuseIdentifier, for: indexPath) as? ImageCell {
           galleryPresenter.fetchImageBy(indexPath: indexPath, targetSize: self.defaultImageSize) {
                (uiImage) in
                if let uiImage = uiImage {
                    DispatchQueue.main.async {
                        cell.image.image = uiImage
                        cell.image.contentMode = .scaleAspectFill
                    }
                }
            }
            if galleryPresenter.isCellLoading(indexPath: indexPath) {
                cell.startAnimatingSpinner()
                print(indexPath.row)
            }
            return cell
        } else {
            // ? a better approach for the fail case?
            print("📕", "No cell for index: \(indexPath.row) in: cellForItemAt. Creating new ImageCell")
            return ImageCell()
        }
        
    }
}

// MARK: - Clicking an image/cell
extension GalleryCollectionViewController: UICollectionViewDelegate {
        
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        print("cell number \(indexPath.row) was pressed")
        if let imageCell = collectionView.cellForItem(at: indexPath) as? ImageCell,
           let uiImage = imageCell.image.image {
            imageCell.startAnimatingSpinner()
            self.galleryPresenter.cellPressed(uiImage: uiImage, cellOfImage: imageCell, indexPath: indexPath)
        } else {
            print("📕", "error selecting a cell at \(indexPath.row)")
        }
    }
}

// MARK: - Presenter Delegate
extension GalleryCollectionViewController: GalleryPresenterDelegate {

    func refreshGallery(){
        self.collectionView.reloadData()
    }
    
    func didUploadImageLink(indexPath: IndexPath) {
        DispatchQueue.main.async {
            if let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCell {
                    cell.stopAnimatingSpinner()
            } else {
                print("No cell for index: \(indexPath) in: didUploadImageLink")
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath) {
        DispatchQueue.main.async {
            if let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCell {
                    print(additionalMessage)
                    print(error ?? "")
                    let alert = UIAlertController(title: "Upload Failed", message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                    cell.stopAnimatingSpinner()
            } else {
                print("📕", "No cell for index: \(indexPath.row) in: didFailWithError")
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}
