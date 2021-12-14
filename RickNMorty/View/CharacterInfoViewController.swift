//
//  CharacterInfoViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 14.12.2021.
//

import UIKit
import Nuke

class CharacterInfoViewController: UIViewController {

    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var characterImage: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var speciesLabel: UILabel!
    @IBOutlet var genderLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var episodesCountLabel: UILabel!
    
    var character = Characters()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        Nuke.loadImage(with: URL(string: character!.image), options: options, into: characterImage)
        
        nameLabel.text = character?.name
        statusLabel.text = character?.status
        speciesLabel.text = character?.species
        genderLabel.text = character?.gender
        locationLabel.text = character?.location
        episodesCountLabel.text = String(character!.episodes.count)
    }
}
