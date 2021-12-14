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
    var name: String = "Персонаж"
    var image: String = ""
    var maxCount: Int = 0
    var id: Int = 0
    
    init?(charactersData: CharactersData, andIndex index: Int) {
        name = charactersData.results[index].name
        image = charactersData.results[index].image
        id = charactersData.results[index].id
    }
    
    init?(charactersDataShort: CharactersDataShort) {
        name = charactersDataShort.name
        image = charactersDataShort.image
        id = charactersDataShort.id
    }
    
    init?(name1: String, image1: String, id1: String) {
        name = name1
        image = image1
        id = Int(id1)!
    }
    
    
    init?(){
        
    }
}
