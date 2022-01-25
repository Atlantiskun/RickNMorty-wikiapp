//
//  CharacterItem+CoreDataProperties.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 13.01.2022.
//
//

import Foundation
import CoreData

extension CharacterItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CharacterItem> {
        NSFetchRequest<CharacterItem>(entityName: "CharacterItem")
    }

    @NSManaged public var name: String
    @NSManaged public var id: Int16
    @NSManaged public var status: String
    @NSManaged public var species: String
    @NSManaged public var gender: String
    @NSManaged public var location: String
    @NSManaged public var episodes: [String]
    @NSManaged public var imageUrl: URL?
    @NSManaged public var image: Data

}

extension CharacterItem : Identifiable {

}
