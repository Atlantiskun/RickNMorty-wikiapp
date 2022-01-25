//
//  charactersViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 29.11.2021.
//

import UIKit
import Nuke
import Network
import CoreData

class CollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let charactersUrl: String = "https://rickandmortyapi.com/api/character"
    let networkManager = NetworkManager()
    var loadingView: LoadingReusableView?
    var emptyFooterView: EmptyFooterReusableView?
    var characters: [Characters] = []
    var countOfAllCharacters = 0
    var numberOfCharactersToShow = 0
    var page = 1
    var isLoading = false
    var nextPage = ""
    var favouritesStorage: MyFavouritesStorageProtocol = MyFavouritesStorage()
    var saveToStorage: [CharacterProtocol] = [] {
        didSet {
            favouritesStorage.save(saveToStorage)
        }
    }
    
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
        CollectionViewController.persistentContainer.viewContext
    }
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    var internetIsAvailable = true
    
    var oldTabIndex = 0
    
    private var models: [CharacterItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.tabBarController?.delegate = self

        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.collectionView.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        collectionView.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        
        let emptyFooterReusableNib = UINib(nibName: "EmptyFooterReusableView", bundle: nil)
        collectionView.register(emptyFooterReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "emptyfooter")
        
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied {
                internetIsAvailable = true
                getAllItems()
                if models.isEmpty {
                    loadData()
                } else {
                    for item in models {
                        characters.append(Characters(charactersItem: item))
                    }
                    nextPage = "?page=\(page)"
                    page += 1
                    self.networkManager.getNumberOfPagesAndCountFrom(url: self.charactersUrl) { info in
                        if let charactersInfo = info {
                            self.countOfAllCharacters = charactersInfo.0
                        }
                    }
                    
                    networkManager.getCharactersFrom(page: nextPage) { charactersList in
                        for characterIndex in 0..<charactersList.count {
                            if !charactersList[characterIndex].isEqual(with: models[characterIndex]) {
                                updateItem(item: models[characterIndex], with: charactersList[characterIndex])
                            }
                        }
                        getAllItems()
                    }
                    numberOfCharactersToShow += 20
                }
            } else {
                internetIsAvailable = false
                getAllItems()
                if !models.isEmpty {
                    for item in models {
                        characters.append(Characters(charactersItem: item))
                    }
                    self.countOfAllCharacters = models.count
                    self.numberOfCharactersToShow += 20
                }
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: nil, message: "There is no internet connection. To get complete and up-to-date data, you need an internet connection", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    
                    collectionView.reloadData()
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        collectionView.reloadData()
    }
    
    func loadData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                self.networkManager.getNumberOfPagesAndCountFrom(url: self.charactersUrl) { info in
                    if let charactersInfo = info {
                        self.countOfAllCharacters = charactersInfo.0
                    }
                    self.numberOfCharactersToShow += 20
                }
                self.nextPage = "?page=\(self.page)"
                self.page += 1
                self.networkManager.getCharactersFrom(page: self.nextPage) { charactersList in
                    for character in charactersList {
                        self.characters.append(character)
                        self.createItem(from: character)
                    }
                }
                self.saveToStorage = self.favouritesStorage.loadFavourites()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.getAllItems()
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func loadMoreData() {
        if internetIsAvailable {
            if !self.isLoading {
                self.isLoading = true
                DispatchQueue.global().async {
                    self.nextPage = "?page=\(self.page)"
                    self.page += 1
                    
                    if self.numberOfCharactersToShow + 20 > self.countOfAllCharacters {
                        self.numberOfCharactersToShow += self.countOfAllCharacters - self.numberOfCharactersToShow
                    } else {
                        self.numberOfCharactersToShow += 20
                    }
                    
                    self.networkManager.getCharactersFrom(page: self.nextPage) { charactersList in
                        for characterIndex in 0..<charactersList.count {
                            if self.models.count < characterIndex + self.numberOfCharactersToShow + 1 {
                                self.characters.append(charactersList[characterIndex])
                                self.createItem(from: charactersList[characterIndex])
                                self.getAllItems()
                            } else if !charactersList[characterIndex].isEqual(with: self.models[characterIndex + self.numberOfCharactersToShow - 20]) {
                                self.updateItem(item: self.models[characterIndex + self.numberOfCharactersToShow - 20], with: charactersList[characterIndex])
                                self.getAllItems()
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.collectionView.reloadData()
                    }
                }
            }
        } else {
            if self.numberOfCharactersToShow + 20 > self.models.count {
                self.numberOfCharactersToShow = self.models.count
            } else {
                self.numberOfCharactersToShow += 20
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - Core Data Func
extension CollectionViewController {
    func getAllItems() {
        do {
            models = try context.fetch(CharacterItem.fetchRequest())
            DispatchQueue.main.async {
                self.collectionView.reloadData()
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

// MARK: - Layout
extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            if self.characters.isEmpty && !internetIsAvailable {
                guard let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyfooter", for: indexPath) as? EmptyFooterReusableView else {
                    return EmptyFooterReusableView()
                }
                
                emptyFooterView = aFooterView
                emptyFooterView?.backgroundColor = UIColor.white
                
                aFooterView.frame.size.height = self.collectionView.frame.height - 60
                aFooterView.frame.size.width = self.collectionView.frame.width
                
                return aFooterView
            } else {
                guard let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loadingresuableviewid", for: indexPath) as? LoadingReusableView else {
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
            return CGSize(width: collectionView.bounds.size.width, height: 55)
        }
    }
}

// MARK: - Delegate, DataSource
extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfCharactersToShow
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as? CollectionViewItemCell else {
            return UICollectionViewCell()
        }
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        
        if characters.count > indexPath.row {
            if models.count >= numberOfCharactersToShow {
                cell.imageView.image = UIImage(data: models[indexPath.row].image)
                
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
        if indexPath.row == numberOfCharactersToShow - 10  && !self.isLoading {
            loadMoreData()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "CharacterInfoSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "CharacterInfoSegue":
            prepareCharactersInfo(segue)
        default:
            break
        }
    }
    
    private func prepareCharactersInfo(_ segue: UIStoryboardSegue) {
        if let destinationController = segue.destination as? CharacterInfoViewController,
           let indexPath = collectionView.indexPathsForSelectedItems {
            destinationController.character = models[indexPath[0].row]
        }
    }
}

// MARK: - Scroll to top after tap on tab bar icon
extension CollectionViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        guard let navigationController = self.navigationController else {
            return
        }
        if tabBarIndex == 0 && oldTabIndex == tabBarIndex {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: -(navigationController.navigationBar.frame.height)), animated: true)
        }
        self.oldTabIndex = tabBarIndex
    }
}

// MARK: - Add to favourites action
extension CollectionViewController {
    @objc func addToFavourites(_ sender: UIButton){
        if sender.currentBackgroundImage == UIImage(systemName: "heart") {
            saveToStorage.append(characters[sender.tag])
            sender.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            let message = "You added \(characters[sender.tag].name) to favourites"
            notifyUser(title: nil, message: message, timeToDissapear: 2)
        } else {
            for index in 0..<saveToStorage.count {
                if saveToStorage[index].id == characters[sender.tag].id {
                    saveToStorage.remove(at: index)
                    break
                }
            }
            sender.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            let message = "You removed \(characters[sender.tag].name) from favourites"
            notifyUser(title: nil, message: message, timeToDissapear: 2)
        }
    }
    
    func notifyUser(title: String?, message: String?, timeToDissapear: Int) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}
