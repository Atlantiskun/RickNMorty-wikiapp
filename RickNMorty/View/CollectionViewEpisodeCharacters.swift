//
//  CollectionViewEpisodeCharacters.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 02.12.2021.
//

import UIKit
import Nuke
import Network
import CoreData

class CollectionViewEpisodeCharacters: UIViewController {

    @IBOutlet var collectionViewEpisode: UICollectionView!
    
    let networkManager = NetworkManager()
    var charactersOnEpisodeUrls: [String] = []
    var charactersOnEpisodeId: [String] = []
    var charactersNeedToDownload: [String] = []
    
    var characters: [Characters] = []
    
    var countOfAllCharacters = 0
    var numberOfCharactersToShow = 0
    var loadingView: LoadingReusableView?

    var favouritesStorage: MyFavouritesStorageProtocol = MyFavouritesStorage()
    var saveToStorage: [CharacterProtocol] = [] {
        didSet {
            favouritesStorage.save(saveToStorage)
        }
    }
    
    var isLoading = false
    
    private static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RIckNMorty")
        container.loadPersistentStores { _, error in
            if let error = error {
                print(error)
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        Self.persistentContainer.viewContext
    }
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    var internetIsAvailable = true
    var emulateInternetDown = false
    
    private var models: [CharacterItem] = []
    private var charactersOnPage: [CharacterItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionViewEpisode.delegate = self
        self.collectionViewEpisode.dataSource = self
        
        self.countOfAllCharacters = charactersOnEpisodeUrls.count
        
        getAllItems()
        
        // Register Item Cell
        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.collectionViewEpisode.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        // Register Loading Reuseable View
        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        collectionViewEpisode.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied && !emulateInternetDown {
                internetIsAvailable = true
                getAllItems()
                if models.isEmpty {
                    loadData()
                } else {
                    loadDataCoreData()
                }
            } else {
                internetIsAvailable = false
                getAllItems()
                if !models.isEmpty {
                    loadDataCoreData()
                }
            }
        }

        monitor.start(queue: queue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        collectionViewEpisode.reloadData()
    }

    func loadData() {
        collectionViewEpisode.collectionViewLayout.invalidateLayout()
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                for characterUrl in self.charactersOnEpisodeUrls {
                    self.networkManager.getCharacterFrom(urlString: characterUrl) { character in
                        self.characters.append(character)
                    }
                    self.saveToStorage = self.favouritesStorage.loadFavourites()
                }
                
                if self.charactersOnEpisodeUrls.count < 20 {
                    self.numberOfCharactersToShow = self.charactersOnEpisodeUrls.count
                } else {
                    self.numberOfCharactersToShow += 20
                }
                
                DispatchQueue.main.async {
                    self.collectionViewEpisode.reloadData()
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadDataCoreData() {
        for onEpisodeIndex in 0..<charactersOnEpisodeUrls.count {
            for index in 0..<models.count {
                if charactersOnEpisodeUrls[onEpisodeIndex] == "https://rickandmortyapi.com/api/character/\(models[index].id)" {
                    characters.append(Characters(charactersItem: models[index]))
                    if charactersOnPage == nil {
                        charactersOnPage = [models[index]]
                    } else {
                        charactersOnPage?.append(models[index])
                    }
                    break
                } else if index == models.count - 1 {
                    charactersNeedToDownload.append(charactersOnEpisodeUrls[onEpisodeIndex])
                    if internetIsAvailable {
                        networkManager.getCharacterFrom(urlString: charactersOnEpisodeUrls[onEpisodeIndex]) { [self] characterFromURL in
                            if charactersOnPage == nil {
                                charactersOnPage = [createItem(from: characterFromURL)]
                            } else {
                                charactersOnPage?.append(createItem(from: characterFromURL))
                            }
                        }
                    }
                }
            }
        }
        if self.internetIsAvailable {
            if self.charactersOnEpisodeUrls.count < 20 {
                self.numberOfCharactersToShow = self.charactersOnEpisodeUrls.count
            } else {
                self.numberOfCharactersToShow += 20
            }
        } else {
            numberOfCharactersToShow = self.characters.count
            countOfAllCharacters = self.characters.count
        }
        
        if !charactersNeedToDownload.isEmpty {
            if self.internetIsAvailable {
                for character in charactersNeedToDownload {
                    networkManager.getCharacterFrom(urlString: character) { characterFromURL in
                        self.characters.append(characterFromURL)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: nil, message: "Have not information about \(self.charactersNeedToDownload.count) character(s).", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    
                    self.collectionViewEpisode.reloadData()
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        DispatchQueue.main.async {
            self.collectionViewEpisode.reloadData()
        }
    }
    
    func loadMoreData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                if self.internetIsAvailable {
                    if self.numberOfCharactersToShow + 20 > self.countOfAllCharacters {
                        self.numberOfCharactersToShow += self.countOfAllCharacters - self.numberOfCharactersToShow
                    } else {
                        self.numberOfCharactersToShow += 20
                    }
                } else {
                    self.numberOfCharactersToShow = self.characters.count
                    self.countOfAllCharacters = self.characters.count
                }
                
                DispatchQueue.main.async {
                    self.collectionViewEpisode.reloadData()
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Layout
extension CollectionViewEpisodeCharacters: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let aFooterView = collectionViewEpisode.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loadingresuableviewid", for: indexPath) as? LoadingReusableView else {
                return LoadingReusableView()
            }
            loadingView = aFooterView
            loadingView?.backgroundColor = UIColor.clear
            if self.numberOfCharactersToShow == self.countOfAllCharacters {
                aFooterView.frame.size.height = 0
                aFooterView.frame.size.width = 0
            }
            return aFooterView
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.startAnimating()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.stopAnimating()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.isLoading {
            return CGSize.zero
        } else {
            return CGSize(width: collectionViewEpisode.bounds.size.width, height: 55)
        }
    }
}

// MARK: - Delegate, DataSource
extension CollectionViewEpisodeCharacters: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfCharactersToShow
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as? CollectionViewItemCell else {
            return CollectionViewItemCell()
        }
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        
        if characters.count > indexPath.row {
            if let character = characters.last,
               models.count >= character.id {
                if let character = charactersOnPage?[indexPath.row] {
                    cell.imageView.image = UIImage(data: character.image)
                }
            } else {
                let imageUrlString = characters[indexPath.row].image
                Nuke.loadImage(with: URL(string: imageUrlString), options: options, into: cell.imageView)
            }
            
            cell.addToFavourites.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            for index in 0..<saveToStorage.count {
                if saveToStorage[index].id == characters[indexPath.row].id {
                    cell.addToFavourites.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
                }
            }
            cell.addToFavourites.frame.size = CGSize(width: 50, height: 44)
            cell.addToFavourites.addTarget(self, action: #selector(addToFavourites), for: .touchUpInside)
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
        }
        
        cell.addToFavourites.tag = indexPath.row
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == numberOfCharactersToShow - 10  && !self.isLoading && numberOfCharactersToShow != countOfAllCharacters {
            loadMoreData()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "fromEpisodeDetailToCharacterDetail", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "fromEpisodeDetailToCharacterDetail":
            prepareCharactersInfo(segue)
        default:
            break
        }
    }
    
    private func prepareCharactersInfo(_ segue: UIStoryboardSegue) {
        if let destinationController = segue.destination as? CharacterInfoViewController,
           let indexPath = collectionViewEpisode.indexPathsForSelectedItems {
            
            if let character = charactersOnPage?[indexPath[0].row] {
                destinationController.character = character
            }
        }
    }

}

// MARK: - Core Data Func
extension CollectionViewEpisodeCharacters {
    
    func getAllItems() {
        do {
            models = try context.fetch(CharacterItem.fetchRequest())
            DispatchQueue.main.async {
                self.collectionViewEpisode.reloadData()
            }
        } catch {
            // Error
        }
    }
    
    func createItem(from characterData: Characters) {
        let newItem = CharacterItem(context: context)
        
        newItem.name = characterData.name
        newItem.imageUrl = URL(string: characterData.image)
        newItem.id = Int16(characterData.id)
        newItem.status = characterData.status
        newItem.species = characterData.species
        newItem.gender = characterData.gender
        newItem.location = characterData.location
        newItem.episodes = characterData.episodes
        
        if let url = newItem.imageUrl {
            do {
                newItem.image = try Data(contentsOf: url)
            } catch {
                // Error
            }
        }
        
        do {
            try context.save()
        } catch {
            // Error
        }
    }
    
    func createItem(from characterData: Characters) -> CharacterItem {
        let newItem = CharacterItem(context: context)
        
        newItem.name = characterData.name
        newItem.imageUrl = URL(string: characterData.image)
        newItem.id = Int16(characterData.id)
        newItem.status = characterData.status
        newItem.species = characterData.species
        newItem.gender = characterData.gender
        newItem.location = characterData.location
        newItem.episodes = characterData.episodes
        
        if let url = newItem.imageUrl {
            do {
                newItem.image = try Data(contentsOf: url)
            } catch {
                // Error
            }
        }
        
        return newItem
    }
    
    func deleteItem(item: CharacterItem) {
        context.delete(item)
        
        do {
            try context.save()
        } catch {
            // Error
        }
    }
    
    func updateItem(item: CharacterItem, with characterData: Characters) {
        item.name = characterData.name
        item.imageUrl = URL(string: characterData.image)
        item.id = Int16(characterData.id)
        item.status = characterData.status
        item.species = characterData.species
        item.gender = characterData.gender
        item.location = characterData.location
        item.episodes = characterData.episodes
        
        if let url = item.imageUrl {
            do {
                item.image = try Data(contentsOf: url)
            } catch {
                // Error
            }
        }
        
        do {
            try context.save()
        } catch {
            // Error
        }
    }
    
    func clearCoredata() {
        getAllItems()
        for item in models {
            deleteItem(item: item)
        }
        do {
            try context.save()
            getAllItems()
        } catch {
            // Error
        }
    }
}

// MARK: Add to favourites action
extension CollectionViewEpisodeCharacters {
    @objc func addToFavourites(_ sender: UIButton){
        if sender.currentBackgroundImage == UIImage(systemName: "heart") {
            saveToStorage.append(characters[sender.tag])
            sender.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            notifyUser(title: nil, message: "You added \(characters[sender.tag].name) to favourites", timeToDissapear: 2)
        } else {
            for index in 0..<saveToStorage.count {
                if saveToStorage[index].id == characters[sender.tag].id {
                    saveToStorage.remove(at: index)
                    break
                }
            }
            sender.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            notifyUser(title: nil, message: "You removed \(characters[sender.tag].name) from favourites", timeToDissapear: 2)
        }
    }
    
    func notifyUser(title: String?, message: String?, timeToDissapear: Int) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}
