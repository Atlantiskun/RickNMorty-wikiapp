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
    
    init?(episodesData: EpisodesData, andIndex index: Int) {
        name = episodesData.results[index].name
        episodeCode = episodesData.results[index].episode
        characters = episodesData.results[index].characters
        date = episodesData.results[index].airDate
    }
    
    init?(episodesData: EpisodesResult) {
        name = episodesData.name
        episodeCode = episodesData.episode
        characters = episodesData.characters
        date = episodesData.airDate
    }
    
    init(){
        
    }
}
