//
//  NetworkManager.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import Foundation


struct NetworkManager {
    
    func getNumberOfPagesAndCount(urlString: String, complitionHandler: @escaping ((Int, Int)?) -> Void) {
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
            
            if let dataInfo = self.parseJSONCount(withData: data) {
                complitionHandler(dataInfo)
            }
        }
        
        task.resume()
    }
    
    func parseJSONCount(withData data: Data) -> (Int, Int)? {
        let decoder = JSONDecoder()
        do {
            let infoData = try decoder.decode(InfoData.self, from: data)
            return (infoData.info.count, infoData.info.pages)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    

    func fetchData(nextPage page: String, complitionHandler: @escaping ([Characters]) -> Void) {
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
            if let charactersDataInfo = self.parseJSON(withData: data) {
                complitionHandler(charactersDataInfo)
            }
        }
        
        task.resume()
    }
    
    func parseJSON(withData data: Data) -> [Characters]?{
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
    
    
    func fetchShortData(urlString: String, complitionHandler: @escaping (Characters) -> Void) {
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
            if let charactersDataInfo = self.parseJSONshort(withData: data) {
                complitionHandler(charactersDataInfo)
            }
        }
        
        task.resume()
    }
    
    func parseJSONshort(withData data: Data) -> Characters?{
        let decoder = JSONDecoder()
        
        do {
            let charactersData = try decoder.decode(PartsResult.self, from: data)
            guard let character = Characters(charactersDataShort: charactersData) else {
                return nil
            }
            
            return (character)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func findCharacters(searchName name: String, complitionHandler: @escaping ([Characters]) -> Void) {
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
            if let charactersDataInfo = self.parseJSON(withData: data) {
                complitionHandler(charactersDataInfo)
            } else {
                complitionHandler([])
            }
        }
        
        task.resume()
    }
    
    func fetchEpisodesData(nextPage: Int, complitionHandler: @escaping ([Episodes]) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/episode?page=\(nextPage)"
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
            if let episodesDataInfo = self.parseJSONEpisodes(withData: data) {
                complitionHandler(episodesDataInfo)
            }
        }
        
        task.resume()
    }
    
    func parseJSONEpisodes(withData data: Data) -> [Episodes]?{
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
    
    func findEpisodesWithCharacter(episodeUrls: [String], complitionHandler: @escaping ([Episodes]) -> Void) {
        
        var episodesToReturn: [Episodes] = []
        for episodeUrl in episodeUrls {
            guard let url = URL(string: episodeUrl) else {
                return
            }
            
            var request = URLRequest(url: url, timeoutInterval: Double.infinity)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                if let episodesDataInfo = self.parseJSONEpisodesChar(withData: data) {
//                    print(episodesDataInfo)
                    episodesToReturn.append(episodesDataInfo)
                }
            }
            
            task.resume()
        }
        print(episodesToReturn.count)
        complitionHandler(episodesToReturn)
    }
    
    func parseJSONEpisodesChar(withData data: Data) -> Episodes? {
        let decoder = JSONDecoder()
        var episode: Episodes
        
        do {
            let episodesData = try decoder.decode(EpisodesResult.self, from: data)
            guard let parsedEpisode = Episodes(episodesData: episodesData) else {
                return nil
            }
            episode = parsedEpisode
            
            return (episode)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
}
