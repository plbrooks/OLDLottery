//
//  PickerTableViewCell.swift
//  Lottery
//
//  Created by Peter Brooks on 9/28/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit

class PickerTableViewCell: UITableViewCell {

    @IBOutlet weak var leftPicker: UIPickerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
