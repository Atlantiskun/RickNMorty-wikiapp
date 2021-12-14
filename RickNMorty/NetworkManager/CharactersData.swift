//
//  Charachters.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import Foundation


struct CharactersData: Decodable {
    let results: [PartsResult]
}

struct PartsResult: Decodable {
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

enum tempAvgGender: String, Decodable {
    case female = "Female"
    case male = "Male"
    case unknown = "unknown"
}

enum tempAvgStatus: String, Decodable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
}

enum tempAvgSpecies: String, Decodable {
    case alien = "Alien"
    case human = "Human"
    case animal = "Animal"
    
}

struct CharactersDataShort: Decodable {
    let id: Int
    let name: String
    let image: String
}
