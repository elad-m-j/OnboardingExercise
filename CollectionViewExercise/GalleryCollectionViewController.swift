import UIKit
import Photos

class GalleryCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    let bobImage = UIImage.init(imageLiteralResourceName: "bob")
    
    var networkManager = NetworkManager()
    let marginForCell: CGFloat = 5
    var imagesPerRow = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPhotoCollection()
        collectionView.delegate = self
        collectionView.dataSource = self
        networkManager.delegate = self
        
        setCellsSize()
    }
    
    // MARK: - Cell size setting
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with:coordinator)
        if size.height >= size.width { // portrait (?)
            imagesPerRow = 3
        } else {
            imagesPerRow = 5
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

// MARK: - Data source and view layout
extension GalleryCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPhotoAssets?.count ?? -1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellReuseIdentifier, for: indexPath) as! ImageCell
        let photoAsset = userPhotoAssets?.object(at: indexPath.row)
        
        cell.image.fetchImageFrom(asset: photoAsset, contentMode: .aspectFill, targetSize: cell.image.frame.size)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let noOfCellsInRow = imagesPerRow   //number of column you want
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: size)
    }
}

extension GalleryCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("cell number \(indexPath.row) was pressed")
        if let photoAsset = userPhotoAssets?.object(at: indexPath.row){
            let options = PHImageRequestOptions()
            options.version = .original
            PHImageManager.default().requestImage(for: photoAsset, targetSize: CGSize(width: 150, height: 150), contentMode: .aspectFit, options: options) { (image, _) in
                guard let image = image else {return}
                self.networkManager.uploadImageToImgur(image: image)
//                self.networkManager.requestImage()
            }
        } else {
            print("Failed retreiving asset from collection")
        }
        
        //spinner load
        // error message
        // link to save in network delegate
    }
}

// MARK: - Network
extension GalleryCollectionViewController: NetworkManagerDelegate {
    func didImageLinkUpload(_ networkManager: NetworkManager, imageLink: ImageLink) {
        // should save link here somehow
//        print(imageLink)
    }
    
    func didFailWithError(error: Error) {
        print(error)
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
                                                  contentMode: contentMode,
                                                  options: options) { (image, _) in
                guard let image = image else {return}
                switch contentMode {
                    case .aspectFill:
                        self.contentMode = .scaleAspectFill
                    case .aspectFit:
                        self.contentMode = .scaleAspectFit
                    @unknown default:
                        print("non existent image content mode")
                }
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
