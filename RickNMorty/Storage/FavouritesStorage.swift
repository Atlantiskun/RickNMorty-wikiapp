//
//  FavouritesStorage.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 08.12.2021.
//

import Foundation

protocol MyFavouritesStorageProtocol {
    func loadFavourites() -> [CharacterProtocol]
    func save(_ favouriets: [CharacterProtocol])
}

class MyFavouritesStorage: MyFavouritesStorageProtocol {
    private var storage = UserDefaults.standard
    var storageKey: String = "ricknmortyfavourites"
    
    func loadFavourites() -> [CharacterProtocol] {
        var resultCharacters: [CharacterProtocol] = []
        let charactersFromStorage = storage.array(forKey: storageKey) as? [[String:String]] ?? []
        
        for character in charactersFromStorage {
            guard let name = character["name"],
                  let id = character["id"],
                  let image = character["image"] else {
                continue
            }
            resultCharacters.append(Characters(name: name, image: image, id: id))
        }
        
        return resultCharacters
    }
    
    func save(_ favouriets: [CharacterProtocol]) {
        var arrayFroStorage: [[String:String]] = []
        favouriets.forEach { character in
            var newElementForStorage: [String:String] = [:]
            newElementForStorage["name"] = character.name
            newElementForStorage["image"] = character.image
            newElementForStorage["id"] = String(character.id)
            arrayFroStorage.append(newElementForStorage)
        }
        storage.set(arrayFroStorage, forKey: storageKey)
    }
}
