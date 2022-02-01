//
//  Charachters.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import Foundation
protocol CharacterProtocol {
    var name: String { get set }
    var image: String { get set }
    var id: Int { get set }
    
}

struct Characters: CharacterProtocol {
    var name: String = ""
    var image: String = ""
    var id: Int = 0
    var status: String = ""
    var species: String = ""
    var gender: String = ""
    var location: String = ""
    var episodes: [String] = []
    
    init?(charactersData: CharactersData, andIndex index: Int) {
        name = charactersData.results[index].name
        image = charactersData.results[index].image
        id = charactersData.results[index].id
        status = charactersData.results[index].status.rawValue
        species = charactersData.results[index].species
        gender = charactersData.results[index].gender
        location = charactersData.results[index].location.name
        episodes = charactersData.results[index].episode
    }
    
    init?(charactersDataShort: CharacterResult) {
        name = charactersDataShort.name
        image = charactersDataShort.image
        id = charactersDataShort.id
        status = charactersDataShort.status.rawValue
        species = charactersDataShort.species
        gender = charactersDataShort.gender
        location = charactersDataShort.location.name
        episodes = charactersDataShort.episode
    }
    
    init(charactersItem: CharacterItem) {
        name = charactersItem.name
        if let imageUrl = charactersItem.imageUrl?.absoluteString {
            image = imageUrl
        }
        id = Int(charactersItem.id)
        status = charactersItem.status
        species = charactersItem.species
        gender = charactersItem.gender
        location = charactersItem.location
        episodes = charactersItem.episodes
    }
    
    init(name: String, image: String, id: String) {
        self.name = name
        self.image = image
        self.id = Int(id) ?? 0
    }
    
    init(){
    }
}

extension Characters {
    func isEqual(with characterItem: CharacterItem) -> Bool {
        
        if self.name == characterItem.name,
           self.id == Int(characterItem.id),
           self.status == characterItem.status,
           self.species == characterItem.species,
           self.gender == characterItem.gender,
           self.location == characterItem.location,
           self.episodes == characterItem.episodes {
            return true
        } else {
            return false
        }
        
    }
}
