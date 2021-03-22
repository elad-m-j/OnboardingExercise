import UIKit
import Photos

/// Shows all photos in user's Photos Gallery
class GalleryCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    
    private var galleryPresenter = GalleryPresenter(with: NetworkService())
    var imagesPerRow = 3.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        galleryPresenter.delegate = self
        galleryPresenter.fetchPhotoCollection()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    /// Cell resizing when orientation changes
    override func viewWillTransition(to size: CGSize,
            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with:coordinator)
        imagesPerRow = size.height >= size.width ? 3.0 : 5.0
        coordinator.animate { _ in
            // calls sizeForItemAt eventually
            self.collectionView.collectionViewLayout.invalidateLayout()
        } completion: { _ in }
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
        let numberOfCellsInRow = imagesPerRow   //number of columns you want
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfCellsInRow - 1))
        let squareWidth = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfCellsInRow))
        return CGSize(width: squareWidth, height: squareWidth)
    }
    
}

// MARK: - Data source
extension GalleryCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPhotoAssets?.count ?? -1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellReuseIdentifier, for: indexPath) as! ImageCell
        
        let photoAsset = userPhotoAssets?.object(at: indexPath.row)
        cell.image.fetchImageFrom(asset: photoAsset, contentMode: .aspectFill, targetSize: cell.image.frame.size)
        
        return cell
    }
}

// MARK: - Clicking an image/cell
extension GalleryCollectionViewController: UICollectionViewDelegate {
    
    private func getBase64Image(image: UIImage) -> String? {
        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        return base64Image
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        print("cell number \(indexPath.row) was pressed")
        if let photoAsset = userPhotoAssets?.object(at: indexPath.row),
           let imageCell = collectionView.cellForItem(at: indexPath) as? ImageCell {
            let options = PHImageRequestOptions()
            options.version = .original
            PHImageManager.default().requestImage(for: photoAsset, targetSize: CGSize(width: 300, height: 300), contentMode: .default, options: options) { (image, _) in
                print("in request")
                if let image = image,
                   let base64Image = self.getBase64Image(image: image) {
                    imageCell.startAnimatingSpinner()
                    self.galleryPresenter.uploadImageToImgur(withBase64StringAsImage: base64Image, cellOfImage: imageCell)
                }
            }
        } else {
            print("Failed retrieving asset from collection")
        }
    }
}

// MARK: - Presenter Delegate
extension GalleryCollectionViewController: GalleryPresenterDelegate {
    
    func setAssets(photoAssets: PHFetchResult<PHAsset>){
        self.userPhotoAssets = photoAssets
        self.collectionView.reloadData()
    }
    
    func didUploadImageLink(cellOfImage: ImageCell) {
        DispatchQueue.main.async {
            cellOfImage.stopAnimatingSpinner()
        }
    }
    
    func didFailWithError(error: Error?, additionalMessage: String, _ cellOfImage: ImageCell) {
        DispatchQueue.main.async {
            print(additionalMessage)
            print(error ?? "")
            let alert = UIAlertController(title: "Upload Failed", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
            cellOfImage.stopAnimatingSpinner()
        }
    }
}

// MARK: - Fetch UIImage from asset
extension UIImageView{
    
    func fetchImageFrom(asset: PHAsset?, contentMode: PHImageContentMode, targetSize:CGSize) {
        
        if asset == nil {
            return // doesn't seem swifty enough
        } else {
            let options = PHImageRequestOptions()
            options.version = .original
            PHImageManager.default().requestImage(for: asset!,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: options) {
                (image, _) in
                guard let image = image else {return}
                switch contentMode {
                    case .aspectFill:
                        self.contentMode = .scaleAspectFill
                    case .aspectFit:
                        self.contentMode = .scaleAspectFit
                    default:
                        print("non existent image content mode")
                }
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

