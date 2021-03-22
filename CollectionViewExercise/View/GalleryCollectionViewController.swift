import UIKit
import Photos

class GalleryCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    let bobImage = UIImage.init(imageLiteralResourceName: "bob")
    
    var networkManager = NetworkService()
    private var galleyPresenter = GalleryPresenter(with: NetworkService())
    let marginForCell: CGFloat = 5
    var imagesPerRow = 3.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        fetchPhotoCollection()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        networkManager.delegate = self
        
    }
    
    // MARK: - Cell size setting
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with:coordinator)
        if size.height >= size.width {
            imagesPerRow = 3.0
        } else {
            imagesPerRow = 5.0
        }
        coordinator.animate { (_) in
            // calls sizeForItemAt
            self.collectionView.collectionViewLayout.invalidateLayout()
        } completion: { (_) in
        }

    }
    
    private func setCellsSize(){
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {return}
        flowLayout.minimumInteritemSpacing = marginForCell
        flowLayout.minimumLineSpacing = marginForCell
        flowLayout.sectionInset = UIEdgeInsets(top: marginForCell, left: marginForCell, bottom: marginForCell, right: marginForCell)
        
    }
    
    // MARK: - fetching user photos
    private func fetchPhotoCollection(){
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                    case .authorized:
                        print("Authorized")
                        self.authorizedFetch()
                    case .denied, .restricted:
                        print("Not allowed")
                    case .notDetermined:
                        print("Not determined yet")
                    case .limited:
                        print("Limited access")
                    @unknown default:
                        print("default case in permissions")
                }
            }
        }
    }
    
    private func authorizedFetch(){
        let photosCollection: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: nil)
        self.userPhotoAssets = photosCollection
        self.collectionView.reloadData()
    }
    
    // MARK: - Navigation
    @IBAction func linksPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constants.segueLinksIdentifier, sender: self)
    }
}

extension GalleryCollectionViewController: UICollectionViewDelegateFlowLayout {
    /// Handles the images per row constraint
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

// MARK: - Data source and view layout
extension GalleryCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPhotoAssets?.count ?? -1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellReuseIdentifier, for: indexPath) as! ImageCell
        
        let photoAsset = userPhotoAssets?.object(at: indexPath.row)
        cell.image.fetchImageFrom(asset: photoAsset, contentMode: .aspectFill, targetSize: cell.image.frame.size)
        
        cell.image.image = bobImage
        return cell
    }
}

extension GalleryCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        print("cell number \(indexPath.row) was pressed")
        if let photoAsset = userPhotoAssets?.object(at: indexPath.row),
           let imageCell = collectionView.cellForItem(at: indexPath) as? ImageCell{
            let options = PHImageRequestOptions()
            options.version = .original
            PHImageManager.default().requestImage(for: photoAsset, targetSize: CGSize(width: 300, height: 300), contentMode: .default, options: options) { (image, _) in
                guard let image = image else {return}
                imageCell.startAnimatingSpinner()
                self.networkManager.uploadImageToImgur(withUIImage: image, cellOfImage: imageCell)
            }
        } else {
            print("Failed retrieving asset from collection")
        }
    }
}

// MARK: - Network
extension GalleryCollectionViewController: NetworkServiceDelegate {
    
    func didUploadImageLink(_ networkManager: NetworkService, cellOfImage: ImageCell) {
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

