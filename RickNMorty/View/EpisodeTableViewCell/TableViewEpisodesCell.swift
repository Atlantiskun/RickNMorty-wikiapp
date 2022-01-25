//
//  TableViewEpisodesCell.swift
//  RickNMorty
//
//  Created by Дмитрий Болучевских on 02.12.2021.
//

import UIKit

class TableViewEpisodesCell: UITableViewCell {

    @IBOutlet var episodeLabel: UILabel!
    @IBOutlet var episodeCodeLabel: UILabel!
    @IBOutlet var episodeDataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
