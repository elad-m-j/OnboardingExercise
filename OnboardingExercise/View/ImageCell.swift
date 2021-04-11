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
    func shouldDisplayImage(indexPath: IndexPath)
    func pressed(indexPath: IndexPath)
}

/// Image cell in gallery mainly handles the spinner animation
class ImageCell: UICollectionViewCell, ImageCellProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    private lazy var spinner = UIActivityIndicatorView(style: .large)
    private var presenter: ImageCellPresenterProtocol?
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
    func shouldDisplayImage(indexPath: IndexPath) {
        print("shouldDisplay: \(indexPath.row)")
        presenter = ImageCellPresenter(indexPath: indexPath)
        presenter?.view = self
        index = indexPath.row
        presenter?.shouldDisplayImage() {
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
    
    func pressed(indexPath: IndexPath) {
//        startAnimatingSpinner()
        presenter?.cellPressed(indexPath: indexPath)
        
    }
    
    func startAnimatingSpinner() {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
    }
    
    func stopAnimatingSpinner() {
        DispatchQueue.main.async {
            print("stopAnimatingSpinner: \(String(describing: self.index))")
            self.spinner.stopAnimating()
        }
    }
    
    override func prepareForReuse() {
        print("reusing cell: \(String(describing: index))")
        index = nil
        imageView.image =  nil
        presenter = nil
        stopAnimatingSpinner()
        super.prepareForReuse()
    }
}

extension ImageCell: ImageCellPresenterDelegate {
    
    func didUploadImageLink(indexPath: IndexPath) {
//        stopAnimatingSpinner()
    }
    
    func didFailWithError(error: Error?, additionalMessage: String, indexPath: IndexPath) {
        delegateVC?.showAlert(error: error, additionalMessage: additionalMessage)
        stopAnimatingSpinner()
    }
}
