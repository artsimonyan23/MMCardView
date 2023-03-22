//
//  CustomCardLayout.swift
//  Pods
//
//  Created by MILLMAN on 2016/9/20.
//
//

import UIKit

class CardLayoutAttributes: UICollectionViewLayoutAttributes {
    var isExpand = false

    override func copy(with zone: NSZone? = nil) -> Any {
        let attribute = super.copy(with: zone) as! CardLayoutAttributes
        attribute.isExpand = isExpand
        return attribute
    }
}

@objc
public protocol CustomCardLayoutDelegate {
    @objc
    optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: CustomCardLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
}

public class CustomCardLayout: UICollectionViewLayout {
    public weak var delegate: CustomCardLayoutDelegate?

    public var selectPath: IndexPath? {
        set {
            _selectPath = (_selectPath == newValue) ? nil : newValue
            setBottomStackIndexes()
            collectionView?.performBatchUpdates({
                self.invalidateLayout()
            }, completion: nil)
        } get {
            return _selectPath
        }
    }

    public var isFullScreen = false {
        didSet {
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadData()
            }, completion: nil)
        }
    }

    public var defaultCardHeight: CGFloat = 300 {
        didSet {
            collectionView?.performBatchUpdates({
                self.invalidateLayout()
            }, completion: nil)
        }
    }

    public var titleHeight: CGFloat = 56 {
        didSet {
            collectionView?.performBatchUpdates({
                self.invalidateLayout()
            }, completion: nil)
        }
    }

    public var bottomStackCount = 6 {
        didSet {
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadData()
            }, completion: nil)
        }
    }

    public var bottomTitleHeight: CGFloat = 20 {
        didSet {
            collectionView?.performBatchUpdates({
                self.invalidateLayout()
            }, completion: nil)
        }
    }

    public var bottomMinScale: CGFloat = 0.94

    public var bottomMaxScale: CGFloat = 1

    private func cellSize(for indexPath: IndexPath) -> CGSize {
        guard let collectionView = collectionView else { return .zero }
        if let size = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
            return size
        }
        let w = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let size = CGSize(width: w, height: defaultCardHeight)
        return size
    }

    fileprivate var insertPath = [IndexPath]()
    fileprivate var deletePath = [IndexPath]()
    fileprivate var attributeList = [CardLayoutAttributes]() {
        didSet {
            setBottomStackIndexes()
        }
    }

    private var minIndex = -1
    private var maxIndex = -1

    private var countedSelectPath: IndexPath?

    private func setBottomStackIndexes() {
        guard countedSelectPath != selectPath else { return }
        minIndex = -1
        maxIndex = -1
        if let index = attributeList.firstIndex(where: { $0.indexPath == selectPath }) {
            countedSelectPath = selectPath
            let half = Int(bottomStackCount / 2)
            minIndex = index - half
            maxIndex = index + half

            if minIndex < 0 {
                minIndex = 0
                maxIndex = index + half + abs(index - half)
                if bottomStackCount % 2 == 1 {
                    maxIndex += 1
                }
            } else if maxIndex >= attributeList.count {
                minIndex = (attributeList.count - 2 * half) - 1
                maxIndex = attributeList.count - 1
                if bottomStackCount % 2 == 1 {
                    minIndex -= 1
                }
            } else {
                if bottomStackCount % 2 == 1 {
                    if minIndex > 0 {
                        minIndex -= 1
                    } else {
                        maxIndex += 1
                    }
                }
            }
            minIndex = max(0, minIndex)
            maxIndex = min(attributeList.count - 1, maxIndex)
        } else {
            countedSelectPath = nil
        }
    }

    public enum SequenceStyle: Int {
        case normal
        case cover
    }

    public var showStyle: SequenceStyle = .cover {
        didSet {
            collectionView?.performBatchUpdates({
                self.invalidateLayout()
            }, completion: nil)
        }
    }

    fileprivate var _selectPath: IndexPath? {
        didSet {
            collectionView!.isScrollEnabled = (_selectPath == nil)
        }
    }

    override public var collectionViewContentSize: CGSize {
        set {}
        get {
            guard let collectionView = collectionView else {
                return super.collectionViewContentSize
            }
            let sections = collectionView.numberOfSections
            let total = (0 ..< sections).reduce(0) { total, current -> Int in
                total + self.collectionView!.numberOfItems(inSection: current)
            }
            let section = collectionView.numberOfSections - 1
            let item = collectionView.numberOfItems(inSection: section) - 1
            let lastCellSize = cellSize(for: IndexPath(item: item, section: section))
            let contentHeight = titleHeight * CGFloat(total - 1) + lastCellSize.height
            return CGSize(width: lastCellSize.width, height: contentHeight)
        }
    }

    override public func prepare() {
        super.prepare()

        let update = collectionView!.calculate.isNeedUpdate()

        if let select = selectPath, !update {
            var bottomIdx: Int = 0
            attributeList.forEach { item in
                if item.indexPath == select {
                    setSelect(attribute: item)
                } else {
                    setBottom(attribute: item, bottomIdx: &bottomIdx)
                }
            }
        } else {
            _selectPath = nil
            if !update && collectionView!.calculate.totalCount == attributeList.count {
                attributeList.forEach({ [unowned self] in
                    self.setNoSelect(attribute: $0)
                })
                return
            }
            let list = generateAttributeList()
            if list.count > 0 {
                attributeList.removeAll()
                attributeList += list
            }
        }
    }

    fileprivate func generateAttributeList() -> [CardLayoutAttributes] {
        var arr = [CardLayoutAttributes]()
        let offsetY = collectionView!.contentOffset.y > 0 ? collectionView!.contentOffset.y : 0
        let startIdx = abs(Int(offsetY / titleHeight))
        let sections = collectionView!.numberOfSections
        var itemsIdx = 0

        for sec in 0 ..< sections {
            let count = collectionView!.numberOfItems(inSection: sec)
            if itemsIdx + count - 1 < startIdx {
                itemsIdx += count
                continue
            }
            for item in 0 ..< count {
                if itemsIdx >= startIdx {
                    let indexPath = IndexPath(item: item, section: sec)
                    let attr = CardLayoutAttributes(forCellWith: indexPath)
                    attr.zIndex = itemsIdx
                    setNoSelect(attribute: attr)
                    arr.append(attr)
                }
                itemsIdx += 1
            }
        }
        return arr
    }

    fileprivate func setNoSelect(attribute: CardLayoutAttributes) {
        attribute.transform = .identity
        let shitIdx = Int(collectionView!.contentOffset.y / titleHeight)
        if shitIdx < 0 {
            return
        }
        attribute.isExpand = false
        let index = attribute.zIndex
        var currentFrame = CGRect.zero
        currentFrame = CGRect(x: collectionView!.frame.origin.x, y: titleHeight * CGFloat(index), width: cellSize(for: attribute.indexPath).width, height: cellSize(for: attribute.indexPath).height)
        switch showStyle {
        case .cover:
            if index <= shitIdx && (index >= shitIdx) {
                attribute.frame = CGRect(x: currentFrame.origin.x, y: collectionView!.contentOffset.y, width: cellSize(for: attribute.indexPath).width, height: cellSize(for: attribute.indexPath).height)
            } else if index <= shitIdx && currentFrame.maxY > collectionView!.contentOffset.y {
                currentFrame.origin.y -= (currentFrame.maxY - collectionView!.contentOffset.y)
                attribute.frame = currentFrame
            } else {
                attribute.frame = currentFrame
            }

        case .normal:
            attribute.frame = currentFrame
        }
    }

    fileprivate func setSelect(attribute: CardLayoutAttributes) {
        attribute.transform = .identity
        attribute.isExpand = true
        // 0.01 prevent no reload
        attribute.frame = CGRect(x: collectionView!.frame.origin.x, y: collectionView!.contentOffset.y + 0.01, width: cellSize(for: attribute.indexPath).width, height: cellSize(for: attribute.indexPath).height)
    }

    fileprivate func setBottom(attribute: CardLayoutAttributes, bottomIdx: inout Int) {
        guard let collectionView = collectionView else { return }
        attribute.transform = .identity
        attribute.isExpand = false
        attribute.frame.size = cellSize(for: attribute.indexPath)
        var y = collectionView.contentOffset.y + collectionView.bounds.height
        if bottomIdx >= minIndex, bottomIdx <= maxIndex, !isFullScreen {
            let bottomIdx = bottomIdx - minIndex
            let margin: CGFloat = CGFloat(bottomStackCount - bottomIdx)
            y -= margin * bottomTitleHeight
            attribute.frame.origin = CGPoint(x: 0, y: y)
            let scale: CGFloat = calculateCardScale(forIndex: CGFloat(bottomIdx))
            attribute.transform = CGAffineTransform(scaleX: scale, y: scale)
        } else if bottomIdx < minIndex {
            let margin: CGFloat = CGFloat(bottomStackCount)
            y -= margin * bottomTitleHeight
            attribute.frame.origin = CGPoint(x: 0, y: y)
            let scale: CGFloat = calculateCardScale(forIndex: CGFloat(0))
            attribute.transform = CGAffineTransform(scaleX: scale, y: scale)
        } else {
            attribute.frame.origin = CGPoint(x: 0, y: y)
        }
        bottomIdx += 1
    }

    private var scalePerCard: CGFloat {
        let minimumScale = (bottomMaxScale < bottomMinScale) ? bottomMaxScale : bottomMinScale
        return (bottomMaxScale - minimumScale) / CGFloat(bottomStackCount)
    }

    private func calculateCardScale(forIndex index: CGFloat, scaleBehindCard: Bool = false) -> CGFloat {
        let addedDownScale: CGFloat = (scaleBehindCard == true && index < CGFloat(bottomStackCount)) ? scalePerCard : 0.0
        return min(1.0, bottomMaxScale - (((index + 1 - CGFloat(bottomStackCount)) * -1) * scalePerCard) - addedDownScale)
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let first = attributeList.first(where: { $0.indexPath == indexPath }) else {
            let attr = CardLayoutAttributes(forCellWith: indexPath)
            return attr
        }
        return first
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var reset = rect
        reset.origin.y = collectionView!.contentOffset.y

        let arr = attributeList.filter {
            var fix = $0.frame
            fix.size.height = titleHeight
            return fix.intersects(reset)
        }
        return arr
    }

    override public func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let at = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        if deletePath.contains(itemIndexPath) {
            if let original = attributeList.first(where: { $0.indexPath == itemIndexPath }) {
                at?.frame = original.frame
            }
            let randomLoc = (itemIndexPath.row % 2 == 0) ? 1 : -1
            let x = collectionView!.frame.width * CGFloat(randomLoc)
            at?.transform = CGAffineTransform(translationX: x, y: 0)
        }

        return at
    }

    override public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let at = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        if insertPath.contains(itemIndexPath) {
            let randomLoc = (itemIndexPath.row % 2 == 0) ? 1 : -1
            let x = collectionView!.frame.width * CGFloat(-randomLoc)
            at?.transform = CGAffineTransform(translationX: x, y: 0)
        }
        return at
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        deletePath.removeAll()
        insertPath.removeAll()
        for update in updateItems {
            if update.updateAction == .delete {
                let path = (update.indexPathBeforeUpdate != nil) ? update.indexPathBeforeUpdate : update.indexPathAfterUpdate
                if let p = path {
                    deletePath.append(p)
                }
            } else if let path = update.indexPathAfterUpdate, update.updateAction == .insert {
                insertPath.append(path)
            }
        }
    }

    override public func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        if deletePath.count > 0 || insertPath.count > 0 {
            deletePath.removeAll()
            insertPath.removeAll()
            let vi = collectionView!.subviews.sorted {
                $0.layer.zPosition < $1.layer.zPosition
            }
            vi.forEach({ vi in
                collectionView?.addSubview(vi)
            })
        }
    }
}
