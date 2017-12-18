//
//  CustomCycleBannerViewCell.swift
//  Example
//
//  Created by Jiar on 2017/12/18.
//  Copyright © 2017年 Jiar. All rights reserved.
//

import UIKit
import CycleBanner

class CustomCycleBannerViewCell: CycleBannerViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
    
    func config(_ title: String) {
        titleLabel.text = title
    }
    
}
