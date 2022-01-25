//
//  EpisodesViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 01.12.2021.
//

import UIKit
import Nuke
import CoreData
import Network

class EpisodesViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    let networkManager = NetworkManager()
    var episodes: [Episodes] = []
    var episodesForCheck: [Episodes] = []

    var isLoading = false
    let episodesUrl: String = "https://rickandmortyapi.com/api/episode"
    var isShortInfo = false
    var passedCharacter = String()
    
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
        Self.persistentContainer.viewContext
    }

    private var coredataEpisodes: [EpisodeItem] = []
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied && !isShortInfo {
                DispatchQueue.main.async {
                    self.navigationItem.title = "All episodes"
                }
                getAllItems()
                
                if coredataEpisodes.isEmpty {
                    loadData()
                } else {
                    for item in coredataEpisodes {
                        episodes.append(Episodes(episodesItem: item))
                    }
                    self.networkManager.getNumberOfPagesAndCountFrom(url: self.episodesUrl) { info in
                        if let charactersInfo = info {
                            for page in 1...charactersInfo.1 {
                                self.networkManager.getEpisodesFrom(page: page) { episodesList in
                                    for episode in episodesList {
                                        self.episodesForCheck.append(episode)
                                        if self.episodesForCheck.count > self.episodes.count {
                                            createItem(from: episode)
                                        } else if !episode.isEqual(with: coredataEpisodes[self.episodesForCheck.count - 1]) {
                                            updateItem(item: coredataEpisodes[self.episodesForCheck.count - 1], with: episode)
                                        }
                                        
                                        getAllItems()
                                    }
                                    
                                }
                            }
                        }
                       
                    }
                }
            } else if pathUpdateHandler.status != .satisfied  && !isShortInfo {
                getAllItems()
                if coredataEpisodes.isEmpty {
                    addFooterAlert()
                } else {
                    for item in coredataEpisodes {
                        episodes.append(Episodes(episodesItem: item))
                    }
                }
            } else if isShortInfo {
                DispatchQueue.main.async {
                    self.navigationItem.title = "All episodes with \(passedCharacter)"
                }
                if pathUpdateHandler.status != .satisfied && episodes.isEmpty {
                    addFooterAlert()
                }
            }
        }

        monitor.start(queue: queue)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
                                    self.episodes.append(episode)
                                    self.createItem(from: episode)
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.getAllItems()
                    self.tableView.reloadData()
                }
            }
        }
    }
}

// MARK: - Footer alert
extension EpisodesViewController {
    func addFooterAlert() {
        DispatchQueue.main.async {
            guard let navigationController = self.navigationController else {
                return
            }
            let footerView = UIView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: self.tableView.frame.width,
                                                  height: self.tableView.frame.height - navigationController.navigationBar.frame.height))
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width - 40, height: 50))
            label.center = CGPoint(x: footerView.frame.width / 2, y: footerView.frame.height / 2)
            label.textAlignment = .center
            label.contentMode = .scaleToFill
            label.numberOfLines = 0
            
            label.text = "Sorry, you havn't offline data about episodes. You need internet connection to download it."
            
            footerView.backgroundColor = .white
            footerView.addSubview(label)
            self.tableView.tableFooterView = footerView
        }
    }
}

// MARK: - TableView func
extension EpisodesViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "tableviewepisodecellid", for: indexPath) as? TableViewEpisodesCell else {
            return TableViewEpisodesCell()
        }
        cell.episodeLabel.text = "\(episodes[indexPath.row].name)"
        cell.episodeCodeLabel.text = "\(episodes[indexPath.row].episodeCode)"
        cell.episodeDataLabel.text = "\(episodes[indexPath.row].date)"
        cell.backgroundColor = .white
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toEpisodeCharacters":
            prepareCharactersOnEpisodeScreen(segue)
        default:
            break
        }
    }
    
    private func prepareCharactersOnEpisodeScreen(_ segue: UIStoryboardSegue) {
        guard let destinationController = segue.destination as? CollectionViewEpisodeCharacters else {
            return
        }
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationController.charactersOnEpisodeUrls = episodes[indexPath.row].characters
        }
    }
}

// MARK: - Core Data Func
extension EpisodesViewController {
    func getAllItems() {
        do {
            coredataEpisodes = try context.fetch(EpisodeItem.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            // Error
        }
    }
    
    func createItem(from episodeData: Episodes) {
        let newItem = EpisodeItem(context: context)
        
        newItem.name = episodeData.name
        newItem.code = episodeData.episodeCode
        newItem.date = episodeData.date
        newItem.charactersURL = episodeData.characters
        newItem.id = Int16(episodeData.id)
        
        do {
            try context.save()
        } catch {
            // Error
        }
    }

    func updateItem(item: EpisodeItem, with episodeData: Episodes) {
        
        item.name = episodeData.name
        item.code = episodeData.episodeCode
        item.date = episodeData.date
        item.charactersURL = episodeData.characters
        item.id = Int16(episodeData.id)
        
        do {
            try context.save()
        } catch {
            // Error
        }
    }
}
