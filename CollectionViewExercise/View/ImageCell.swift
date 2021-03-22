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
    var isLoading = false
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
        
        if isLoading {
            startAnimatingSpinner()
        }
    }
    
    func startAnimatingSpinner(){
        spinner.startAnimating()
        isLoading = true
    }
    
    func stopAnimatingSpinner(){
        spinner.stopAnimating()
        isLoading = false
    }
}
