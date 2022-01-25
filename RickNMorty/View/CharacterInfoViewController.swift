//
//  CharacterInfoViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 14.12.2021.
//

import UIKit
import CoreData
import Network

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
    
    var character: CharacterItem?
    var networkManager = NetworkManager()
    var episodes: [Episodes] = []
    var isLoading = false
    let episodesUrl: String = "https://rickandmortyapi.com/api/episode"
    let characterUrl: String = "https://rickandmortyapi.com/api/character/"
    
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RIckNMorty")
        container.loadPersistentStores { _, error in
            if let error = error {
                print(error)
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        CharacterInfoViewController.persistentContainer.viewContext
    }
    
    private var coredataEpisodes: [EpisodeItem] = []
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let passedCharacter = character else {
            return
        }
        nameLabel.text = passedCharacter.name
        episodesWithCharacterButton.setTitle("Episodes with \(passedCharacter.name)", for: .normal)
        statusLabel.text = passedCharacter.status
        speciesLabel.text = passedCharacter.species
        genderLabel.text = passedCharacter.gender
        locationLabel.text = passedCharacter.location
        episodesCountLabel.text = String(passedCharacter.episodes.count)
        characterImage.image = UIImage(data: passedCharacter.image)
        
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            
            getAllItems()
            if coredataEpisodes.isEmpty && pathUpdateHandler.status == .satisfied {
                loadData()
            } else if !coredataEpisodes.isEmpty || pathUpdateHandler.status == .satisfied {
                for item in coredataEpisodes {
                    let proxyEpisode = (Episodes(episodesItem: item))
                    if passedCharacter.episodes.contains("\(self.episodesUrl)/\(proxyEpisode.id)") {
                        self.episodes.append(proxyEpisode)
                    }
                }
            }
        }

        monitor.start(queue: queue)
    }
    func loadData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                self.networkManager.getNumberOfPagesAndCountFrom(url: self.episodesUrl) { info in
                    if let charactersInfo = info {
                        for page in 1...charactersInfo.1 {
                            self.networkManager.getEpisodesFrom(page: page) { episodesList in
                                for episode in episodesList {
                                    if let passedCharacter = self.character,
                                       episode.characters.contains("\(self.characterUrl)\(passedCharacter.id)") {
                                        self.episodes.append(episode)
                                    }
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
        if let passedCharacter = character {
            destinationController.passedCharacter = passedCharacter.name
        }
        
    }
}

// MARK: - Core Data Func
extension CharacterInfoViewController {
    func getAllItems() {
        do {
            coredataEpisodes = try context.fetch(EpisodeItem.fetchRequest())
        } catch {
            // Error
        }
    }
}
