//
//  CardCCell.swift
//  MMCardView
//
//  Created by MILLMAN on 2016/9/21.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import MMCardView
import UIKit

class CardCCell: CardCell {
    @IBOutlet weak var btnClick: UIButton!
    private var callBack: (() -> Void)?

    func clickCallBack(c: @escaping () -> Void) {
        callBack = c
    }

    @IBAction func clickAction() {
        if let c = callBack {
            c()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
