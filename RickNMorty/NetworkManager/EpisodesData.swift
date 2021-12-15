//
//  EpisodesData.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 01.12.2021.
//

import Foundation


struct EpisodesData: Decodable {
    let results: [EpisodesResult]
    let info: PagesInfo
}

struct EpisodesResult: Decodable {
    let name: String
    let episode: String
    let airDate: String
    let characters: [String]
    
    enum CodingKeys: String, CodingKey {
        case name, episode, characters
        case airDate = "air_date"
    }
}
