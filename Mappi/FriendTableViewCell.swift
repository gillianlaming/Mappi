//
//  FriendTableViewCell.swift
//  Mappi
//
//  Created by Cole Makuch on 11/17/19.
//  Copyright © 2019 cse438. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {


    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var placeTitleLabel: UILabel!
    
    @IBOutlet weak var placeDescriptionText: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
