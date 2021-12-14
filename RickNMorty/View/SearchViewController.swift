//
//  SearchViewController.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 03.12.2021.
//

import UIKit
import Nuke

class SearchViewController: UIViewController {

    @IBOutlet var searchResults: UICollectionView!
    
    let networkManager = NetworkManager()
    
    var isSearching = false
    
    var filteredCharacters = [Characters]()
    
    var favouritesStorage: MyFavouritesStorageProtocol = MyFavouritesStorage()
    var saveToStorage: [CharacterProtocol] = [] {
        didSet {
            favouritesStorage.save(saveToStorage)
        }
    }
    weak var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchResults.delegate = self
        self.searchResults.dataSource = self
        
        definesPresentationContext = true
        
        //Register Item Cell
        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.searchResults.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        //Register Loading Reuseable View
        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        searchResults.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        
        self.saveToStorage = self.favouritesStorage.loadFavourites()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.saveToStorage = self.favouritesStorage.loadFavourites()
        searchResults.reloadData()
    }

//    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
//        print("My name is \(filteredCharacters[indexPath.row].name), i am on \(indexPath.row)")
//    }
    
    @objc func addToFavourites(_ sender: UIButton){
        if sender.currentBackgroundImage == UIImage(systemName: "heart") {
            saveToStorage.append(filteredCharacters[sender.tag])
            sender.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            notifyUser(title: nil, message: "Вы добавили персонажа \(filteredCharacters[sender.tag].name) в избранное", timeToDissapear: 2)
        } else {
            for index in 0..<saveToStorage.count {
                if saveToStorage[index].id == filteredCharacters[sender.tag].id {
                    saveToStorage.remove(at: index)
                    break
                }
            }
            sender.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            notifyUser(title: nil, message: "Вы удалили персонажа \(filteredCharacters[sender.tag].name) из избранного", timeToDissapear: 2)
        }
    }
    
    
    
    func notifyUser(title: String?, message: String?, timeToDissapear: Int) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredCharacters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as! CollectionViewItemCell
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        
        if filteredCharacters.count > indexPath.row {
            let imageUrlString = filteredCharacters[indexPath.row].image
            Nuke.loadImage(with: URL(string: imageUrlString), options: options, into: cell.imageView)
            
            cell.addToFavourites.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            for index in 0..<saveToStorage.count {
                if saveToStorage[index].id == filteredCharacters[indexPath.row].id {
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

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (kind == UICollectionView.elementKindSectionHeader) {
            let headerView:UICollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        }
        return UICollectionReusableView()

        }
    
    //MARK: - SEARCH

    func resetTimer(searchText: String) {
        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
            self!.isSearching = true
            self!.filteredCharacters.removeAll()
            self!.networkManager.findCharacters(searchName: searchText) { charactersList in
                if charactersList.isEmpty {
                    print("Нечего выводить")
                } else {
                    for character in charactersList {
                        self!.filteredCharacters.append(character)
                    }
                }
                self!.isSearching = false
                
            }
            repeat {
                self!.searchResults.reloadData()
            } while self!.isSearching
            
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredCharacters.removeAll()
            self.searchResults.reloadData()
        } else {
            resetTimer(searchText: searchText)
        }
        
    }
}

