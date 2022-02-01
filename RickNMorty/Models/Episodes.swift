//
//  Episodes.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 01.12.2021.
//

import Foundation

struct Episodes {
    var name: String = "Эпизод"
    var episodeCode: String = ""
    var characters: [String] = []
    var date: String = ""
    var id: Int = 0
    
    init?(episodesData: EpisodesData, andIndex index: Int) {
        name = episodesData.results[index].name
        episodeCode = episodesData.results[index].episode
        characters = episodesData.results[index].characters
        date = episodesData.results[index].airDate
        id = episodesData.results[index].id
    }
    
    init(episodesItem: EpisodeItem) {
        name = episodesItem.name
        episodeCode = episodesItem.code
        characters = episodesItem.charactersURL
        date = episodesItem.date
        id = Int(episodesItem.id)
    }
    
    init(){
    }
}

extension Episodes {
    func isEqual(with episodeItem: EpisodeItem) -> Bool {
        if self.name == episodeItem.name,
           self.episodeCode == episodeItem.code,
           self.characters == episodeItem.charactersURL,
           self.date == episodeItem.date,
           self.id == Int(episodeItem.id) {
            return true
        } else {
            return false
        }
    }
}
