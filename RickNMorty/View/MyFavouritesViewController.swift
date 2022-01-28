//
//  MyFavouritesViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 08.12.2021.
//
import UIKit
import CoreData
import Nuke
import Network

class MyFavouritesViewController: UIViewController {
    @IBOutlet var collectionViewFavourites: UICollectionView!
    var emptyFooterView: EmptyFooterReusableView?
    
    let networkManager = NetworkManager()
    var charactersOnEpisodeUrls: [String] = []
    
    var characters: [CharacterProtocol] = []
    
    var countOfAllCharacters = 0
    var numberOfCharactersToShow = 0
    var loadingView: LoadingReusableView?

    var isLoading = false
    
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
        MyFavouritesViewController.persistentContainer.viewContext
    }
    
    private var models: [CharacterItem] = []
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    var internetIsAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionViewFavourites.delegate = self
        self.collectionViewFavourites.dataSource = self
        
        self.countOfAllCharacters = charactersOnEpisodeUrls.count
        
        // Register Item Cell
        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.collectionViewFavourites.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        // Register Loading Reuseable View
        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        collectionViewFavourites.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        
        let emptyFooterReusableNib = UINib(nibName: "EmptyFooterReusableView", bundle: nil)
        collectionViewFavourites.register(emptyFooterReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "emptyfooter")
        
        monitor.pathUpdateHandler = { [self] pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied {
                internetIsAvailable = true
            }
        }
        monitor.start(queue: queue)
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.characters = self.favouritesStorage.loadFavourites()
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        collectionViewFavourites.reloadData()
    }
}

// MARK: - Load Data func
extension MyFavouritesViewController {
    func loadData() {
        collectionViewFavourites.collectionViewLayout.invalidateLayout()
        if !self.isLoading {
            getAllItems()
            self.isLoading = true
            DispatchQueue.global().async {
                self.characters = self.favouritesStorage.loadFavourites()
                self.saveToStorage = self.favouritesStorage.loadFavourites()
                
                DispatchQueue.main.async {
                    self.collectionViewFavourites.reloadData()
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadMoreData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                if self.numberOfCharactersToShow + 20 > self.countOfAllCharacters {
                    self.numberOfCharactersToShow += self.countOfAllCharacters - self.numberOfCharactersToShow
                } else {
                    self.numberOfCharactersToShow += 20
                }
                DispatchQueue.main.async {
                    self.collectionViewFavourites.reloadData()
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Core Data Func
extension MyFavouritesViewController {
    func getAllItems() {
        do {
            models = try context.fetch(CharacterItem.fetchRequest())
            DispatchQueue.main.async {
                self.collectionViewFavourites.reloadData()
            }
        } catch {
            // Error
        }
    }
}

// MARK: - Add to favourites
extension MyFavouritesViewController {
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

// MARK: - CollectionView func
extension MyFavouritesViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as? CollectionViewItemCell else {
            return CollectionViewItemCell()
        }
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        
        if characters.count > indexPath.row {
            let imageUrlString = characters[indexPath.row].image
            var maxId = 0
            for character in characters {
                if character.id > maxId {
                    maxId = character.id
                }
            }

            if self.models.count >= maxId {
                for character in models {
                    if let imageUrl = character.imageUrl?.absoluteString,
                       imageUrl == imageUrlString {
                        cell.imageView.image = UIImage(data: character.image)
                    }
                }
            } else {
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
}

extension MyFavouritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.isLoading {
            return CGSize.zero
        } else {
            return CGSize(width: collectionViewFavourites.bounds.size.width, height: 55)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            if self.saveToStorage.isEmpty {
                guard let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyfooter", for: indexPath) as? EmptyFooterReusableView else {
                    return EmptyFooterReusableView()
                }
                
                aFooterView.labelOnFooter.text = "Favourite is empty. Tag anyone character to save it!"
                
                emptyFooterView = aFooterView
                emptyFooterView?.backgroundColor = UIColor.white
                
                aFooterView.frame.size.height = self.collectionViewFavourites.frame.height - 60
                aFooterView.frame.size.width = self.collectionViewFavourites.frame.width
                
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
}
