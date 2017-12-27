//
//  CycleBanner.swift
//  CycleBanner
//
//  Created by Jiar on 2017/12/18.
//  Copyright © 2017年 Jiar. All rights reserved.
//

import UIKit

public protocol CycleBannerViewDelegate: class {
    
    func cycleBannerView(_ cycleBannerView: CycleBannerView, didSelectRowAt index: Int)
    
}

public protocol CycleBannerViewDataSource: class {
    
    func numberOfBanners(in cycleBannerView: CycleBannerView) -> Int
    func cycleBannerView(_ cycleBannerView: CycleBannerView, cellForRowAt index: Int) -> CycleBannerViewCell
    
}

open class CycleBannerViewCell: UIView {
    
    fileprivate var identifier: String?
    fileprivate var selectClosure: (() -> Void)?
    
    @objc fileprivate func selectAction() {
        selectClosure?()
    }
    
}

open class CycleBannerView: UIView {
    
    /// the width for every item
    /// when it is reset, reloadData() method must be called
    open var rowWidth: CGFloat = 0
    /// the space between items
    /// when it is reset, reloadData() method must be called
    open var rowSpace: CGFloat = 0
    /// whether to enable automatic scrolling, default is true
    open var autoSlide = true {
        didSet {
            autoSlideIfNeeded()
        }
    }
    /// whether to hide the bottom pageControl display, default is false
    open var isHiddenPageControl: Bool {
        get {
            return pageControl.isHidden
        }
        set {
            pageControl.isHidden = newValue
        }
    }
    /// automatic scrolling time interval, default is 5
    /// it must be set before the autoSlide property is set to true
    open var timeInterval: TimeInterval = 5
    
    open weak var delegate: CycleBannerViewDelegate?
    open weak var dataSource: CycleBannerViewDataSource?
    
    enum InitMethod {
        case `default`
        case coder(NSCoder)
        case frame(CGRect)
    }
    
    private let pageControl: UIPageControl
    private let scrollView: UIScrollView
    private var pageControlWidthConstraint: NSLayoutConstraint?
    private var scrollViewLeftConstraint: NSLayoutConstraint?
    private var scrollViewRightConstraint: NSLayoutConstraint?
    private var autoSlideTimer: Timer?
    
    private var _rowSpace: CGFloat = 0
    private var _rowWidth: CGFloat = 0
    
    public convenience init() {
        self.init(.default)
    }
    
    public override convenience init(frame: CGRect) {
        self.init(.frame(frame))
    }
    
    public required convenience init(coder aDecoder: NSCoder) {
        self.init(.coder(aDecoder))
    }
    
    private init(_ initMethod: InitMethod) {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        switch initMethod {
        case .default:
            super.init(frame: CGRect.zero)
        case let .coder(coder):
            super.init(coder: coder)!
        case let .frame(frame):
            super.init(frame: frame)
        }
        rowSpace = 10
        rowWidth = width()-2*(rowSpace+10)
        _rowSpace = rowSpace
        _rowWidth = rowWidth
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        addSubview(pageControl)
        setupScrollView()
        setupPageControl()
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.decelerationRate = 0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.layer.masksToBounds = false
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollViewLeftConstraint = scrollView.leftAnchor.constraint(equalTo: leftAnchor, constant: itemOutSpace())
        scrollViewRightConstraint = scrollView.rightAnchor.constraint(equalTo: rightAnchor, constant: -itemOutSpace())
        scrollViewLeftConstraint!.isActive = true
        scrollViewRightConstraint!.isActive = true
    }
    
    private func setupPageControl() {
        pageControl.isUserInteractionEnabled = false
        var pageControlWidth = pageControl.size(forNumberOfPages: pageControl.numberOfPages).width
        if pageControlWidth > width() {
            pageControlWidth = width()
        }
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: pageControlWidth)
        pageControlWidthConstraint?.isActive = true
        pageControl.heightAnchor.constraint(equalToConstant: pageControl.bounds.height).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func autoSlideIfNeeded() {
        if autoSlide {
            enableAutoSlide()
        } else {
            disableAutoSlide()
        }
    }
    
    private func enableAutoSlide() {
        guard autoSlide, autoSlideTimer == nil else {
            return
        }
        autoSlideTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(CycleBannerView.autoSlideAction), userInfo: nil, repeats: true)
    }
    
    private func disableAutoSlide() {
        guard autoSlide, autoSlideTimer != nil else {
            return
        }
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    @objc private func autoSlideAction() {
        guard pageControl.numberOfPages > 1 else {
            return
        }
        scrollView.setContentOffset(CGPoint(x: showCellMinX+2*itemWidth()-_rowSpace/2, y: scrollView.contentOffset.y), animated: true)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: scrollView.bounds.height)
        if scrollView.contentOffset == CGPoint.zero {
            reloadData()
        }
    }
    
    open func reloadData() {
        guard let dataSource = dataSource else {
            return
        }
        disableAutoSlide()
        
        _rowSpace = rowSpace
        _rowWidth = rowWidth
        scrollViewLeftConstraint?.isActive = false
        scrollViewRightConstraint?.isActive = false
        scrollViewLeftConstraint = scrollView.leftAnchor.constraint(equalTo: leftAnchor, constant: itemOutSpace())
        scrollViewRightConstraint = scrollView.rightAnchor.constraint(equalTo: rightAnchor, constant: -itemOutSpace())
        scrollViewLeftConstraint!.isActive = true
        scrollViewRightConstraint!.isActive = true
        
        let numberOfBanners = dataSource.numberOfBanners(in: self)
        pageControl.numberOfPages = numberOfBanners
        pageControlWidthConstraint?.isActive = false
        var pageControlWidth = pageControl.size(forNumberOfPages: pageControl.numberOfPages).width
        if pageControlWidth > width() {
            pageControlWidth = width()
        }
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: pageControlWidth)
        pageControlWidthConstraint?.isActive = true
        scrollView.isScrollEnabled = numberOfBanners > 1
        pageControl.currentPage = 0
        layoutIfNeeded()
        
        for identifier in cellOnShowQueue.keys {
            if let cells =  cellOnShowQueue[identifier] {
                let indexs = (0 ..< cells.count).sorted(by: >)
                for index in indexs {
                    if let cell = cellOnShowQueue[identifier]?.remove(at: index) {
                        cell.frame.origin = .zero
                        cell.removeFromSuperview()
                        if reuseCellQueue[identifier] == nil {
                            reuseCellQueue[identifier] = []
                        }
                        reuseCellQueue[identifier]!.append(cell)
                    }
                }
            }
        }
        
        guard numberOfBanners > 0 else {
            return
        }
        let currentPoint = initCellPoint()
        scrollView.contentOffset = CGPoint(x: currentPoint.x-_rowSpace/2, y: currentPoint.y)
        let currentCell = dataSource.cycleBannerView(self, cellForRowAt: 0)
        setSelectCellClosure(currentCell, index: 0)
        currentCell.frame = CGRect(origin: currentPoint, size: CGSize(width: _rowWidth, height: bounds.height))
        scrollView.addSubview(currentCell)
        showCellMinX = currentCell.frame.minX
        showCellMaxX = currentCell.frame.maxX
        addCellToShowQueue(currentCell)
        
        guard numberOfBanners > 1 else {
            return
        }
        let leftPoint = CGPoint(x: currentPoint.x-itemWidth(), y: currentPoint.y)
        let leftIndex = getIndexByContentOffset(leftPoint)
        let leftCell = dataSource.cycleBannerView(self, cellForRowAt: leftIndex)
        setSelectCellClosure(leftCell, index: leftIndex)
        leftCell.frame = CGRect(origin: leftPoint, size: CGSize(width: _rowWidth, height: bounds.height))
        scrollView.addSubview(leftCell)
        showCellMinX = leftCell.frame.minX
        addCellToShowQueue(leftCell)
        
        let rightPoint = CGPoint(x: currentPoint.x+itemWidth(), y: currentPoint.y)
        let rightIndex = getIndexByContentOffset(rightPoint)
        let rightCell = dataSource.cycleBannerView(self, cellForRowAt: rightIndex)
        setSelectCellClosure(rightCell, index: rightIndex)
        rightCell.frame = CGRect(origin: rightPoint, size: CGSize(width: _rowWidth, height: bounds.height))
        scrollView.addSubview(rightCell)
        showCellMaxX = rightCell.frame.maxX
        addCellToShowQueue(rightCell)
        
        autoSlideIfNeeded()
    }
    
    private func width() -> CGFloat {
        return bounds.width
    }
    private func space() -> CGFloat {
        return (width()-_rowWidth-2*_rowSpace)/2
    }
    private func itemWidth() -> CGFloat {
        return _rowWidth+_rowSpace
    }
    private func itemOutSpace() -> CGFloat {
        return _rowSpace/2+space()
    }
    private func initCellPoint() -> CGPoint {
        return CGPoint(x: CGFloat(10000)*CGFloat(pageControl.numberOfPages)*itemWidth()+_rowSpace/2, y: 0)
    }
    private var showCellMinX: CGFloat = 0
    private var showCellMaxX: CGFloat = 0
    
    private var isNib = false
    private var reuseCellNibQueue: [String: UINib] = [:]
    private var reuseCellClassQueue: [String: CycleBannerViewCell.Type] = [:]
    private var cellOnShowQueue: [String: [CycleBannerViewCell]] = [:]
    private var reuseCellQueue: [String: [CycleBannerViewCell]] = [:]
    
    public func register(_ nib: UINib?, forCellReuseIdentifier identifier: String) {
        isNib = true
        if let nib = nib {
            reuseCellNibQueue[identifier] = nib
        } else {
            reuseCellNibQueue.removeValue(forKey: identifier)
        }
    }
    
    public func register(_ cellClass: CycleBannerViewCell.Type?, forCellReuseIdentifier identifier: String) {
        isNib = false
        if let cellClass = cellClass {
            reuseCellClassQueue[identifier] = cellClass
        } else {
            reuseCellClassQueue.removeValue(forKey: identifier)
        }
    }
    
    public func dequeueReusableCell(withIdentifier identifier: String) -> CycleBannerViewCell {
        var cell: CycleBannerViewCell!
        if reuseCellQueue[identifier] == nil {
            reuseCellQueue[identifier] = []
        }
        if let reuseCell = reuseCellQueue[identifier]!.popLast() {
            cell = reuseCell
        } else {
            if isNib {
                if let nib = reuseCellNibQueue[identifier] {
                    cell = nib.instantiate(withOwner: nil, options: nil)[0] as! CycleBannerViewCell
                } else {
                    assert(false, "not register nib")
                }
            } else {
                if let cellClass = reuseCellClassQueue[identifier] {
                    cell = cellClass.init()
                } else {
                    assert(false, "not register class")
                }
            }
        }
        cell.identifier = identifier
        return cell
    }
    
    fileprivate func showCellsByContentOffset(_ contentOffset: CGPoint) {
        guard let dataSource = dataSource else {
            return
        }
        let screenLeft = contentOffset.x-itemOutSpace()
        let screenRight = screenLeft + width()
        if screenLeft < showCellMinX-_rowSpace {
            let newLeftCellX = showCellMinX-itemWidth()
            let index = getIndexByContentOffset(CGPoint(x: newLeftCellX, y: initCellPoint().y))
            let newLeftCell = dataSource.cycleBannerView(self, cellForRowAt: index)
            setSelectCellClosure(newLeftCell, index: index)
            newLeftCell.frame = CGRect(origin: CGPoint(x: newLeftCellX, y: initCellPoint().y), size: CGSize(width: _rowWidth, height: bounds.height))
            scrollView.addSubview(newLeftCell)
            addCellToShowQueue(newLeftCell)
            showCellMinX = newLeftCell.frame.minX
        }
        if showCellMaxX+_rowSpace < screenRight {
            let newRightCellX = showCellMaxX+_rowSpace
            let index = getIndexByContentOffset(CGPoint(x: newRightCellX, y: initCellPoint().y))
            let newRightCell = dataSource.cycleBannerView(self, cellForRowAt: index)
            setSelectCellClosure(newRightCell, index: index)
            newRightCell.frame = CGRect(origin: CGPoint(x: newRightCellX, y: initCellPoint().y), size: CGSize(width: _rowWidth, height: bounds.height))
            scrollView.addSubview(newRightCell)
            addCellToShowQueue(newRightCell)
            showCellMaxX = newRightCell.frame.maxX
        }
    }
    
    fileprivate func showCellToReuseQueue(_ contentOffset: CGPoint) {
        let scrollViewShowMinX = contentOffset.x-itemOutSpace()
        let scrollViewShowMaxX = scrollViewShowMinX+width()+itemOutSpace()
        var isModify = false
        for identifier in cellOnShowQueue.keys {
            if let cells =  cellOnShowQueue[identifier] {
                var indexs: [Int] = []
                for (index, cell) in cells.enumerated() {
                    let minX = cell.frame.minX
                    let maxX = cell.frame.maxX
                    guard (scrollViewShowMinX <= minX && minX <= scrollViewShowMaxX) || (scrollViewShowMinX <= maxX && maxX <= scrollViewShowMaxX) else {
                        indexs.append(index)
                        continue
                    }
                }
                indexs = indexs.sorted(by: > )
                for index in indexs {
                    isModify = true
                    if let cell = cellOnShowQueue[identifier]?.remove(at: index) {
                        cell.frame.origin = .zero
                        cell.removeFromSuperview()
                        if reuseCellQueue[identifier] == nil {
                            reuseCellQueue[identifier] = []
                        }
                        reuseCellQueue[identifier]!.append(cell)
                    }
                }
            }
        }
        guard isModify else {
            return
        }
        for cells in cellOnShowQueue.values {
            guard cells.count > 0 else {
                continue
            }
            var minX: CGFloat = cells.first!.frame.minX
            var maxX: CGFloat = cells.first!.frame.maxX
            for cell in cells {
                if cell.frame.minX < minX {
                    minX = cell.frame.minX
                }
                if cell.frame.maxX > maxX {
                    maxX = cell.frame.maxX
                }
            }
            showCellMinX = minX
            showCellMaxX = maxX
        }
    }
    
    fileprivate func setCurrentPageByContentOffset(_ contentOffset: CGPoint) {
        let index = getIndexByContentOffset(contentOffset)
        pageControl.currentPage = index
    }
    
    private func getIndexByContentOffset(_ contentOffset: CGPoint) -> Int {
        let offsetInWheel = contentOffset.x.truncatingRemainder(dividingBy: CGFloat(pageControl.numberOfPages)*itemWidth())
        var index = Int(offsetInWheel/itemWidth())
        index = index % pageControl.numberOfPages
        return index
    }
    
    private func setSelectCellClosure(_ cell: CycleBannerViewCell, index: Int) {
        cell.addGestureRecognizer(UITapGestureRecognizer(target: cell, action: #selector(CycleBannerViewCell.selectAction)))
        cell.selectClosure = {
            self.delegate?.cycleBannerView(self, didSelectRowAt: index)
        }
    }
    
    private func addCellToShowQueue(_ cell: CycleBannerViewCell) {
        if let identifier = cell.identifier {
            if cellOnShowQueue[identifier] == nil {
                cellOnShowQueue[identifier] = []
            }
            cellOnShowQueue[identifier]!.append(cell)
        }
    }
    
}

extension CycleBannerView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        showCellsByContentOffset(scrollView.contentOffset)
        showCellToReuseQueue(scrollView.contentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPageByContentOffset(scrollView.contentOffset)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        setCurrentPageByContentOffset(scrollView.contentOffset)
    }
    
}

