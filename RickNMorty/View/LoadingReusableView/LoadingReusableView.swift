//
//  CollectionReusableView.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import UIKit

class LoadingReusableView: UICollectionReusableView {

   @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.color = UIColor.black
    }
}

