//
//  NetworkManager.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import Foundation


struct NetworkManager {
    
    func getNumberOfPagesAndCountFrom(url urlString: String, complitionHandler: @escaping ((Int, Int)?) -> Void) {
        var isCharactersPage = true
        if urlString.contains("episode") {
            isCharactersPage = false
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            
            if let dataInfo = self.getNumberOfPagesAndCountFromJSON(withData: data, flag: isCharactersPage) {
                complitionHandler(dataInfo)
            }
        }
        
        task.resume()
    }
    
    func getNumberOfPagesAndCountFromJSON(withData data: Data, flag: Bool) -> (Int, Int)? {
        let decoder = JSONDecoder()
        do {
            if flag {
                let infoData = try decoder.decode(CharactersData.self, from: data)
                return (infoData.info.count, infoData.info.pages)
            } else {
                let infoData = try decoder.decode(EpisodesData.self, from: data)
                return (infoData.info.count, infoData.info.pages)
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func getCharactersFrom(page: String, complitionHandler: @escaping ([Characters]) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/character/\(page)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let charactersDataInfo = self.getCharactersFromJSON(withData: data) {
                complitionHandler(charactersDataInfo)
            }
        }
        
        task.resume()
    }
    
    func findCharactersBy(name: String, complitionHandler: @escaping ([Characters]) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/character/?name=\(name)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let charactersDataInfo = self.getCharactersFromJSON(withData: data) {
                complitionHandler(charactersDataInfo)
            } else {
                complitionHandler([])
            }
        }
        
        task.resume()
    }
    
    func getCharactersFromJSON(withData data: Data) -> [Characters]?{
        let decoder = JSONDecoder()
        var characters: [Characters] = []
        
        do {
            let charactersData = try decoder.decode(CharactersData.self, from: data)
            for person in 0..<charactersData.results.count{
                guard let character = Characters(charactersData: charactersData, andIndex: person) else {
                    return nil
                }
                characters.append(character)
            }
            return (characters)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    
    func getCharacterFrom(urlString: String, complitionHandler: @escaping (Characters) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let charactersDataInfo = self.getCharacterFromJSON(withData: data) {
                complitionHandler(charactersDataInfo)
            }
        }
        
        task.resume()
    }
    
    func getCharacterFromJSON(withData data: Data) -> Characters?{
        let decoder = JSONDecoder()
        
        do {
            let charactersData = try decoder.decode(CharacterResult.self, from: data)
            guard let character = Characters(charactersDataShort: charactersData) else {
                return nil
            }
            
            return (character)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    
    
    func getEpisodesFrom(page: Int, complitionHandler: @escaping ([Episodes]) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/episode?page=\(page)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let episodesDataInfo = self.getEpisodesFromJSON(withData: data) {
                complitionHandler(episodesDataInfo)
            }
        }
        
        task.resume()
    }
    
    func getEpisodesFromJSON(withData data: Data) -> [Episodes]?{
        let decoder = JSONDecoder()
        var episodes: [Episodes] = []
        
        do {
            let episodesData = try decoder.decode(EpisodesData.self, from: data)
            for episodNumber in 0..<episodesData.results.count{
                guard let episod = Episodes(episodesData: episodesData, andIndex: episodNumber) else {
                    return nil
                }
                episodes.append(episod)
            }
            return (episodes)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}
