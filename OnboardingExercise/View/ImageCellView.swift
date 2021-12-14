//
//  ImageCell.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 11/03/2021.
//

import UIKit

protocol ImageCellViewControllerDelegate: NSObject {
    func showAlert(error: Error?, additionalMessage: String)
}

protocol ImageCellProtocol: UICollectionViewCell {
    var delegateVC: ImageCellViewControllerDelegate? { get set }
    var imageCellPresenter: ImageCellPresenterProtocol? { get }
    func shouldDisplayImage(imageCellPresenter: ImageCellPresenterProtocol, indexPath: IndexPath)
    func pressed(indexPath: IndexPath)
    func stopAnimatingSpinner()
}

/// Image cell in gallery mainly handles the spinner animation
class ImageCellView: UICollectionViewCell, ImageCellProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewNib: UIImageView!
    @IBOutlet weak var spinnerNib: UIActivityIndicatorView!
    
    var imageCellPresenter: ImageCellPresenterProtocol?
    weak var delegateVC: ImageCellViewControllerDelegate?
    var index: Int?
    
    let nibName = "ImageCellView"
    
    convenience init(imageCellPresenter: ImageCellPresenterProtocol) {
        self.init()
        Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        self.imageCellPresenter = imageCellPresenter
    }
    
    func shouldDisplayImage(imageCellPresenter: ImageCellPresenterProtocol, indexPath: IndexPath) {
        index = indexPath.row
        self.imageCellPresenter = imageCellPresenter
        imageCellPresenter.shouldDisplayImage(indexPath: indexPath)
    }

    func pressed(indexPath: IndexPath) {
        imageCellPresenter?.cellPressed(indexPath: indexPath)
    }
    
    override func prepareForReuse() {
        index = nil
        imageView.image =  nil
        imageCellPresenter = nil
        if spinnerNib.isAnimating {
            // Q:assuming main thread here?
            stopAnimatingSpinner()
        }
        super.prepareForReuse()
    }
}

extension ImageCellView: ImageCellViewControllerDelegate {
    func showAlert(error: Error?, additionalMessage: String) {
        print("should show alert in GalleryVC")
    }
}

extension ImageCellView: ImageCellPresenterDelegate {
    
    func displayImage(uiImage: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = uiImage
            self.imageView.contentMode = .scaleAspectFill
        }
    }
    
    func didUploadImageLink(indexPath: IndexPath) {
        stopAnimatingSpinner()
    }
    
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath) {
        print("didFailWithError: \(String(describing: type(of: self)))")
        stopAnimatingSpinner()
    }
    
    func startAnimatingSpinner() {
        self.spinnerNib.startAnimating()
    }
    
    func stopAnimatingSpinner() {
        self.spinnerNib.stopAnimating()
        
    }

}
