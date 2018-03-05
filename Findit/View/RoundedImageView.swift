//
//  RoundedImageView.swift
//  Findit
//
//  Created by Robihamanto on 04/03/18.
//  Copyright © 2018 Robihamanto. All rights reserved.
//

import UIKit

class RoundedImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }
}
