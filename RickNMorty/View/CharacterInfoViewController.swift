//
//  CharacterInfoViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 14.12.2021.
//

import UIKit
import Nuke

class CharacterInfoViewController: UIViewController {

    
    @IBOutlet var characterInfoViewController: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var characterImage: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var speciesLabel: UILabel!
    @IBOutlet var genderLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var episodesCountLabel: UILabel!
    @IBOutlet var episodesWithCharacterButton: UIButton!
    
    var character = Characters()
    var networkManager = NetworkManager()
    var episodes: [Episodes] = []
    var isLoading = false
    let episodesUrl: String = "https://rickandmortyapi.com/api/episode"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        Nuke.loadImage(with: URL(string: character!.image), options: options, into: characterImage)
        
        nameLabel.text = character?.name
        episodesWithCharacterButton.setTitle("Episodes with \(character!.name)", for: .normal)
        statusLabel.text = character?.status
        speciesLabel.text = character?.species
        genderLabel.text = character?.gender
        locationLabel.text = character?.location
        episodesCountLabel.text = String(character!.episodes.count)
        
        loadData()
    }
    
    func loadData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                self.networkManager.getNumberOfPagesAndCountFrom(url: self.episodesUrl) { info in
                    for page in 1...info!.1 {
                        self.networkManager.getEpisodesFrom(page: page) { episodesList in
                            for episode in episodesList {
                                if episode.characters.contains("https://rickandmortyapi.com/api/character/\(self.character!.id)"){
                                    self.episodes.append(episode)
                                }
                            }
                        }
                    }
                    self.isLoading = false
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toEpisodesWtihThisCharacter":
            prepareEpisodesWithCharacter(segue)
        default:
            break
        }
    }
    
    private func prepareEpisodesWithCharacter(_ segue: UIStoryboardSegue) {
        guard let destinationController = segue.destination as? EpisodesViewController else {
            return
        }
        
        destinationController.episodes.removeAll()
        destinationController.episodes = self.episodes
        destinationController.isShortInfo = true
        destinationController.passedCharacter = character!.name
    }
}
