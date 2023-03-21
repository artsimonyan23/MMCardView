//
//  UIViewExtension.swift
//  Pods
//
//  Created by MILLMAN on 2016/9/20.
//
//

import UIKit

extension UIView {
    func setShadow(offset: CGSize, radius: CGFloat, opacity: Float) {
        layer.masksToBounds = false
        layer.cornerRadius = radius
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
    }
}
