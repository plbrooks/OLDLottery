//
//  GameTableViewCell.swift
//  Lottery
//
//  Created by Peter Brooks on 9/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit

class GameTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var GameValue: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
