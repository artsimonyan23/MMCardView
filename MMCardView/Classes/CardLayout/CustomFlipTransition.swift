//
//  CustomFlipTransition.swift
//  Pods
//
//  Created by MILLMAN on 2016/9/21.
//
//

import UIKit

enum TransitionMode: Int {
    case Present, Dismiss
}

public class CustomFlipTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var duration = 0.3
    var transitionMode: TransitionMode = .Present
    var cardView: UICollectionViewCell!
    var originalCardFrame = CGRect.zero
    lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.0
        return blurEffectView
    }()

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)
        let fromView = transitionContext.view(forKey: .from)
        let viewRadius = cardView.layer.cornerRadius

        if transitionMode == .Present {
            originalCardFrame = cardView.frame
            let toViewF = cardView.superview!.convert(cardView.frame, to: nil)
            toView?.frame = cardView.bounds
            toView?.layer.cornerRadius = viewRadius
            cardView.addSubview(toView!)
            blurView.frame = containerView.bounds
            blurView.alpha = 0.0
            containerView.addSubview(blurView)

            UIView.transition(with: cardView, duration: duration, options: [.transitionFlipFromRight, .curveEaseIn], animations: {
                self.cardView.frame = CGRect(x: self.originalCardFrame.origin.x, y: self.originalCardFrame.origin.y, width: toViewF.width, height: toViewF.height)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.blurView.alpha = 1.0
                })
                toView?.frame = toViewF
                toView?.removeFromSuperview()
                containerView.addSubview(toView!)
                transitionContext.completeTransition(true)
            })
        } else {
            cardView.isHidden = true
            let content = cardView.contentView
            let originalCrolor = content.backgroundColor
            content.backgroundColor = cardView.backgroundColor
            content.layer.cornerRadius = viewRadius
            fromView?.addSubview(content)
            UIView.transition(with: fromView!, duration: duration, options: [.transitionFlipFromLeft, .curveEaseInOut], animations: {
                self.blurView.alpha = 0.0
            }, completion: { _ in
                self.blurView.removeFromSuperview()
                content.backgroundColor = originalCrolor
                content.removeFromSuperview()
                self.cardView.addSubview(content)
                self.cardView.isHidden = false
                transitionContext.completeTransition(true)
            })
        }
    }

    public convenience init(duration: TimeInterval) {
        self.init()
        self.duration = duration
    }
}
