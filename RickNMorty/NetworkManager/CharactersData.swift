//
//  Charachters.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import Foundation


struct CharactersData: Decodable {
    let results: [CharacterResult]
    let info: PagesInfo
}

struct PagesInfo: Decodable {
    let count: Int
    let pages: Int
}

struct CharacterResult: Decodable {
    let id: Int
    let name: String
    let image: String
    let status: tempAvgStatus
    let species: String
    let gender: String
    let location: tempAvgLocation
    let episode: [String]
}

struct tempAvgLocation: Decodable {
    let name: String
}

enum tempAvgStatus: String, Decodable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
}
