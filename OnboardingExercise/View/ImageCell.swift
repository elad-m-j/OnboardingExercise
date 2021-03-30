//
//  ImageCell.swift
//  CollectionViewExercise
//
//  Created by Elad Musba on 11/03/2021.
//

import UIKit

/// Image cell in gallery mainly handles the spinner animation
class ImageCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    private lazy var spinner = UIActivityIndicatorView(style: .large)
    
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
    
    func startAnimatingSpinner(){
        spinner.startAnimating()
    }
    
    func stopAnimatingSpinner(){
        spinner.stopAnimating()
    }
    
    override func prepareForReuse() {
        self.image.image =  nil
        self.spinner.stopAnimating()
        super.prepareForReuse()
    }
    
    
}
