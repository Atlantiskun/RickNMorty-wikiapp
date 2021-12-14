//
//  characterCollectionViewCell.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import UIKit

class CollectionViewItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var addToFavourites: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}


