//
//  EpisodesViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 01.12.2021.
//

import UIKit
import Nuke

class EpisodesViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    let networkManager = NetworkManager()
    var episodes: [Episodes] = []

    var isLoading = false
    let episodesUrl: String = "https://rickandmortyapi.com/api/episode"
    var isShortInfo = false
    var passedCharacter = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        if !isShortInfo {
            loadData()
            self.navigationItem.title = "All episodes"
        } else {
            self.navigationItem.title = "All episodes with \(passedCharacter)"
        }
        
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
                    for page in 1...info!.1 {
                        self.networkManager.getEpisodesFrom(page: page) { episodesList in
                            for episode in episodesList {
                                self.episodes.append(episode)
                            }
                        }
                    }
                    self.isLoading = false
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            }
        }
    }
}

extension EpisodesViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableviewepisodecellid", for: indexPath) as! TableViewEpisodesCell
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
        
        destinationController.charactersOnEpisodeUrls = episodes[tableView.indexPathForSelectedRow!.row].characters
    }
}
