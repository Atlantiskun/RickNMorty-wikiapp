//
//  EpisodeItem+CoreDataProperties.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 16.01.2022.
//
//

import Foundation
import CoreData

extension EpisodeItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EpisodeItem> {
        NSFetchRequest<EpisodeItem>(entityName: "EpisodeItem")
    }

    @NSManaged public var name: String
    @NSManaged public var charactersURL: [String]
    @NSManaged public var code: String
    @NSManaged public var date: String
    @NSManaged public var id: Int16

}

extension EpisodeItem : Identifiable {

}
