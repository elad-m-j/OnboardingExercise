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
    func shouldDisplayImage(galleryPresenter: GalleryPresenterProtocol, indexPath: IndexPath)
    func stopAnimatingSpinner()
    func pressed(galleryPresenter: GalleryPresenterProtocol, indexPath: IndexPath)
}

/// Image cell in gallery mainly handles the spinner animation
class ImageCell: UICollectionViewCell, ImageCellProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    private lazy var spinner = UIActivityIndicatorView(style: .large)
    weak var delegateVC: ImageCellViewControllerDelegate?
    var index: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        spinner.alpha = 1
        spinner.color = .white
    }
    
    
    // Where is it best to initialize a presenter? no viewDidLoad here
    // and can't add argument to init
    func shouldDisplayImage(galleryPresenter: GalleryPresenterProtocol, indexPath: IndexPath) {
        index = indexPath.row
        galleryPresenter.shouldDisplayImage(indexPath: indexPath) {
            (uiImage) in
            DispatchQueue.main.async {
                if(NetworkService.shared.isLoadingCell(index: indexPath.row)) {
                    self.startAnimatingSpinner()
                }
                self.imageView.image = uiImage
                self.imageView.contentMode = .scaleAspectFill
            }
        }
    }
    
    func pressed(galleryPresenter: GalleryPresenterProtocol, indexPath: IndexPath) {
        startAnimatingSpinner()
        galleryPresenter.cellPressed(indexPath: indexPath)
    }
    
    func startAnimatingSpinner() {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
    }
    
    func stopAnimatingSpinner() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
        }
    }
    
    override func prepareForReuse() {
        index = nil
        imageView.image =  nil
        if spinner.isAnimating {
            stopAnimatingSpinner()
        }
        super.prepareForReuse()
    }
}
