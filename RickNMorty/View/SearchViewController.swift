//
//  SearchViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 03.12.2021.
//

import CoreData
import UIKit
import Network
import Nuke

class SearchViewController: UIViewController {
    @IBOutlet private var searchResults: UICollectionView!
    let networkManager = NetworkManager()
    var isSearching = false
    var failureSearch = false
    var filteredCharacters = [Characters]()
    var favouritesStorage: MyFavouritesStorageProtocol = MyFavouritesStorage()
    var saveToStorage: [CharacterProtocol] = [] {
        didSet {
            favouritesStorage.save(saveToStorage)
        }
    }
    weak var timer: Timer?
    
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RIckNMorty")
        container.loadPersistentStores { _, error in
            if let error = error {
                print(error)
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        SearchViewController.persistentContainer.viewContext
    }
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    var internetIsAvailable = true
    var emulateInternetDown = false
    private var models: [CharacterItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchResults.delegate = self
        self.searchResults.dataSource = self
        definesPresentationContext = true
        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.searchResults.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        searchResults.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        getAllItems()
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied && !emulateInternetDown {
                internetIsAvailable = true
            } else {
                internetIsAvailable = false
            }
        }
        monitor.start(queue: queue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        searchResults.reloadData()
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.filteredCharacters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as? CollectionViewItemCell else {
            return CollectionViewItemCell()
        }
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        if filteredCharacters.count > indexPath.row {
            if !internetIsAvailable {
                for character in models where filteredCharacters[indexPath.row].id == character.id {
                        cell.imageView.image = UIImage(data: character.image)
                }
            } else {
                let imageUrlString = filteredCharacters[indexPath.row].image
                Nuke.loadImage(with: URL(string: imageUrlString), options: options, into: cell.imageView)
            }
            cell.addToFavourites.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            for index in 0..<saveToStorage.count where saveToStorage[index].id == filteredCharacters[indexPath.row].id {
                    cell.addToFavourites.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            }
            cell.addToFavourites.frame.size = CGSize(width: 50, height: 44)
            cell.addToFavourites.addTarget(self, action: #selector(addToFavourites), for: .touchUpInside)
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
        }
        cell.addToFavourites.tag = indexPath.row
        return cell
    }
}

// MARK: - Layout
extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView:UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        
        case UICollectionView.elementKindSectionFooter:
            let footerView:UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "CollectionViewFooter", for: indexPath)
            return footerView
        default:
            return UICollectionReusableView()

        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if failureSearch {
            return CGSize(width: view.frame.size.width,
                          height: 100)
        }
        return CGSize(width: view.frame.size.width,
                      height: 0)
    }
}

// MARK: - SearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredCharacters.removeAll()
            self.failureSearch = false
            self.searchResults.reloadData()
        } else {
            resetTimer(searchText: searchText)
            self.failureSearch = false
        }
    }
}

// MARK: - Timer
extension SearchViewController {
    func resetTimer(searchText: String) {
        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 0.5, repeats: false) { [self] _ in
            self.isSearching = true
            self.filteredCharacters.removeAll()
            if self.internetIsAvailable {
                self.networkManager.findCharactersBy(name: searchText) { charactersList in
                    if charactersList.isEmpty {
                        self.failureSearch = true
                    } else {
                        for character in charactersList {
                            self.filteredCharacters.append(character)
                        }
                    }
                    self.isSearching = false
                    
                }
                repeat {
                    self.searchResults.reloadData()
                } while self.isSearching
            } else {
                for character in self.models {
                    if character.name.contains(searchText) {
                        self.filteredCharacters.append(Characters(charactersItem: character))
                    }
                }
                if self.filteredCharacters.isEmpty {
                    self.failureSearch = true
                }
                
                self.isSearching = false
                
                self.searchResults.reloadData()
            }
        }
    }
}

// MARK: - Core Data Func
extension SearchViewController {
    func getAllItems() {
        do {
            models = try context.fetch(CharacterItem.fetchRequest())
            DispatchQueue.main.async {
                self.searchResults.reloadData()
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

// MARK: - Add to favourite action
extension SearchViewController {
    @objc func addToFavourites(_ sender: UIButton) {
        if sender.currentBackgroundImage == UIImage(systemName: "heart") {
            saveToStorage.append(filteredCharacters[sender.tag])
            sender.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            let message = "You added \(filteredCharacters[sender.tag].name) to favourites"
            notifyUser(title: nil, message: message, timeToDissapear: 2)
        } else {
            for index in 0..<saveToStorage.count where saveToStorage[index].id == filteredCharacters[sender.tag].id {
                saveToStorage.remove(at: index)
                break
            }
            sender.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            let message = "You removed \(filteredCharacters[sender.tag].name) from favourites"
            notifyUser(title: nil, message: message, timeToDissapear: 2)
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
