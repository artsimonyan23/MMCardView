//
//  MMCardCollectionView.swift
//  Pods
//
//  Created by Millman YANG on 2017/6/21.
//
//

import UIKit

public enum LayoutStyle {
    case card
}

public class MMCollectionView: UICollectionView {
    @IBInspectable var bottomCardsAreSelectable: Bool = true // if 'false', opens all cards
    
    fileprivate var transition = CustomFlipTransition(duration: 0.5)
    fileprivate lazy var _proxyDelegate: DelegateProxy = {
        DelegateProxy(parentObject: self)
    }()

    var layoutStyle: LayoutStyle = .card {
        didSet {
            switch layoutStyle {
            case .card:
                self.collectionViewLayout = cardLayout
            }
        }
    }
    
    public let cardLayout = CustomCardLayout()

    override public var delegate: UICollectionViewDelegate? {
        get {
            return super.delegate
        } set {
            _proxyDelegate.forwardDelegate = newValue
            super.delegate = _proxyDelegate
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }

    func setup() {
        switch collectionViewLayout {
        case _ as CustomCardLayout:
            layoutStyle = .card
        default:
            layoutStyle = .card
        }
    }

    override public var bounds: CGRect {
        didSet {
            if oldValue != bounds && bounds.size != .zero {
                reloadData()
            }
        }
    }

    public func presentViewController(to vc: UIViewController) {
        if (collectionViewLayout as? CustomCardLayout)?.selectPath == nil {
            print("You need select a cell")
            return
        }

        let current = UIViewController.currentViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom
        current.present(vc, animated: true, completion: nil)
    }
}

extension MMCollectionView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let c = cell as? CardCell {
            c.collectionV = collectionView
            c.reloadBlock = {
                if let custom = collectionView.collectionViewLayout as? CustomCardLayout {
                    custom.selectPath = nil
                }
            }
            c.isHidden = false
        }
        _proxyDelegate.forwardDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView.collectionViewLayout {
        case let l as CustomCardLayout:
            if bottomCardsAreSelectable || l.selectPath == nil {
                l.selectPath = indexPath
            } else {
                l.selectPath = nil
            }
        default:
            break
        }
        _proxyDelegate.forwardDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
}

extension MMCollectionView: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        if let custom = collectionViewLayout as? CustomCardLayout, let path = custom.selectPath {
            transition.cardView = cellForItem(at: path)
            custom.isFullScreen = true
        }
        return transition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        if let custom = collectionViewLayout as? CustomCardLayout {
            custom.isFullScreen = false
        }
        return transition
    }
}
