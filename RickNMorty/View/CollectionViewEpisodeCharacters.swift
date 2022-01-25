//
//  CollectionViewEpisodeCharacters.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 02.12.2021.
//

import UIKit
import Nuke

class CollectionViewEpisodeCharacters: UIViewController {

    @IBOutlet var collectionViewEpisode: UICollectionView!
    
    let networkManager = NetworkManager()
    var charactersOnEpisodeUrls: [String] = []
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionViewEpisode.delegate = self
        self.collectionViewEpisode.dataSource = self
        
        self.countOfAllCharacters = charactersOnEpisodeUrls.count
        
        
        // Register Item Cell
        let itemCellNib = UINib(nibName: "CollectionViewItemCell", bundle: nil)
        self.collectionViewEpisode.register(itemCellNib, forCellWithReuseIdentifier: "collectionviewitemcellid")

        // Register Loading Reuseable View
        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        collectionViewEpisode.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")
        
        loadData()
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

extension CollectionViewEpisodeCharacters: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfCharactersToShow
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionviewitemcellid", for: indexPath) as! CollectionViewItemCell
        var options = ImageLoadingOptions()
        options.placeholder = UIImage(named: "placeholder")
        options.transition = .fadeIn(duration: 0.33)
        
        if characters.count > indexPath.row {
            let imageUrlString = characters[indexPath.row].image
            Nuke.loadImage(with: URL(string: imageUrlString), options: options, into: cell.imageView)
            
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
                    self.collectionViewEpisode.reloadData()
                    self.isLoading = false
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.isLoading {
            return CGSize.zero
        } else {
            return CGSize(width: collectionViewEpisode.bounds.size.width, height: 55)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let aFooterView = collectionViewEpisode.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loadingresuableviewid", for: indexPath) as! LoadingReusableView
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
            destinationController.character = characters[indexPath[0].row]
        }
    }

}
