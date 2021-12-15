//
//  ImageCell.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 11/03/2021.
//

import UIKit

protocol ImageCellProtocol: UICollectionViewCell {
    var imageCellPresenter: ImageCellPresenterProtocol? { get }
    func load(imageCellPresenter: ImageCellPresenterProtocol, indexPath: IndexPath)
    func willDisplay(indexPath: IndexPath)
    func didEndDisplaying()
    func pressed(indexPath: IndexPath)
}

class ImageCellView: UICollectionViewCell, ImageCellProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewNib: UIImageView!
    @IBOutlet weak var spinnerNib: UIActivityIndicatorView!
    
    var imageCellPresenter: ImageCellPresenterProtocol?
    var index: Int?
    
    let nibName = "ImageCellView"
    
    convenience init(imageCellPresenter: ImageCellPresenterProtocol) {
        self.init()
        Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        self.imageCellPresenter = imageCellPresenter
    }
    
    func load(imageCellPresenter: ImageCellPresenterProtocol, indexPath: IndexPath) {
        index = indexPath.row
        self.imageCellPresenter = imageCellPresenter
        imageCellPresenter.loadCell(indexPath: indexPath)
    }
    
    func willDisplay(indexPath: IndexPath) {
        guard let cellPresenter = imageCellPresenter else {
            print("no cell presenter mainThread?:\(Thread.isMainThread)")
            return
        }
        cellPresenter.shouldDisplaySpinner(indexPath: indexPath)
    }
    
    func didEndDisplaying() {
        if spinnerNib.isAnimating {
            stopAnimatingSpinner()
        }
    }

    func pressed(indexPath: IndexPath) {
        print("\(indexPath.row): was pressed")
        imageCellPresenter?.cellPressed(indexPath: indexPath)
    }
    
    override func prepareForReuse() {
        if index == 2 {print("\(String(describing: index)): prepare for reuse")}
        index = nil
        imageView.image =  nil
        imageCellPresenter = nil
        super.prepareForReuse()
    }
}

extension ImageCellView: ImageCellPresenterDelegate {
    
    func displayImage(uiImage: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = uiImage
            self.imageView.contentMode = .scaleAspectFill
        }
    }
    
    func startAnimatingSpinner() {
        self.spinnerNib.startAnimating()
    }
    
    func stopAnimatingSpinner() {
        self.spinnerNib.stopAnimating()
        
    }

}
