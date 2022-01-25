//
//  CustomLayout.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import UIKit

class CustomLayout: UICollectionViewFlowLayout {
    @IBInspectable var numberOfItemsPerRow: Int = 0 {
        didSet {
            invalidateLayout()
        }
    }
    
    override func prepare() {
        super.prepare()
        if let collectionView = self.collectionView {
            var newItemSize = itemSize
            let itemsPerRow = CGFloat(max(numberOfItemsPerRow, 1))
            let totalSpacing = minimumInteritemSpacing * (itemsPerRow - 1.0)
            newItemSize.width = (collectionView.bounds.size.width - sectionInset.left - sectionInset.right - totalSpacing) / itemsPerRow
            if itemSize.height > 0 {
                let itemAspectRatio = itemSize.width / itemSize.height
                newItemSize.height = newItemSize.width / itemAspectRatio
            }
            itemSize = newItemSize
        }
    }
}
