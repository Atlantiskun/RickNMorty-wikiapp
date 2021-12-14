//
//  MainData.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 02.12.2021.
//

import Foundation

struct InfoData: Decodable {
    let info: PagesInfo
}

struct PagesInfo: Decodable {
    let count: Int
    let pages: Int
}
