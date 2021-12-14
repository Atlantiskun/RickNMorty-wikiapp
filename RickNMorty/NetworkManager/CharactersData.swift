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
}

struct CharactersDataShort: Decodable {
    let id: Int
    let name: String
    let image: String
}
