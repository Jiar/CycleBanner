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
enum InitMethod {
    case `default`
    case coder(NSCoder)
    case frame(CGRect)
}
open class CycleBannerView: UIView {
    
    enum InitMethod {
        case `default`
        case coder(NSCoder)
        case frame(CGRect)
    }
    
    private let pageControl: UIPageControl
    private let scrollView: UIScrollView
    private var pageControlWidthConstraint: NSLayoutConstraint?
    private var autoSlideTimer: Timer?
    
    open var rowSpace: CGFloat = 0
    open var rowWidth: CGFloat = 0
    
    open var autoSlide = true {
        didSet {
            autoSlideIfNeeded()
        }
    }
    open var isHiddenPageControl: Bool {
        get {
            return pageControl.isHidden
        }
        set {
            pageControl.isHidden = newValue
        }
    }
    open var timeInterval: TimeInterval = 5
    
    open weak var delegate: CycleBannerViewDelegate?
    open weak var dataSource: CycleBannerViewDataSource?
    
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
        rowWidth = width-2*(rowSpace+10)
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
        scrollView.leftAnchor.constraint(equalTo: leftAnchor, constant: itemOutSpace).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor, constant: -itemOutSpace).isActive = true
    }
    
    private func setupPageControl() {
        pageControl.isUserInteractionEnabled = false
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: pageControl.size(forNumberOfPages: pageControl.numberOfPages).width)
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
        guard !autoSlide, autoSlideTimer != nil else {
            return
        }
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    @objc private func autoSlideAction() {
        guard pageControl.numberOfPages > 1 else {
            return
        }
        scrollView.setContentOffset(CGPoint(x: showCellMinX+2*itemWidth-rowSpace/2, y: scrollView.contentOffset.y), animated: true)
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
        let numberOfBanners = dataSource.numberOfBanners(in: self)
        guard numberOfBanners > 0 else {
            return
        }
        if pageControl.numberOfPages != numberOfBanners {
            pageControl.numberOfPages = numberOfBanners
            pageControlWidthConstraint?.isActive = false
            pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: pageControl.size(forNumberOfPages: pageControl.numberOfPages).width)
            pageControlWidthConstraint?.isActive = true
        }
        scrollView.isScrollEnabled = pageControl.numberOfPages > 1
        pageControl.currentPage = 0
        
        let currentCell = dataSource.cycleBannerView(self, cellForRowAt: 0)
        setSelectCellClosure(currentCell, index: 0)
        let currentPoint = initCellPoint
        currentCell.frame = CGRect(origin: currentPoint, size: CGSize(width: rowWidth, height: bounds.height))
        scrollView.addSubview(currentCell)
        showCellMinX = currentCell.frame.minX
        showCellMaxX = currentCell.frame.maxX
        addCellToShowQueue(currentCell)
        scrollView.contentOffset = CGPoint(x: currentPoint.x-rowSpace/2, y: currentPoint.y)
        
        guard numberOfBanners > 1 else {
            return
        }
        let leftPoint = CGPoint(x: currentPoint.x-itemWidth, y: currentPoint.y)
        let leftIndex = getIndexByContentOffset(leftPoint)
        let leftCell = dataSource.cycleBannerView(self, cellForRowAt: leftIndex)
        setSelectCellClosure(leftCell, index: leftIndex)
        leftCell.frame = CGRect(origin: leftPoint, size: CGSize(width: rowWidth, height: bounds.height))
        scrollView.addSubview(leftCell)
        showCellMinX = leftCell.frame.minX
        addCellToShowQueue(leftCell)
        
        let rightPoint = CGPoint(x: currentPoint.x+itemWidth, y: currentPoint.y)
        let rightIndex = getIndexByContentOffset(rightPoint)
        let rightCell = dataSource.cycleBannerView(self, cellForRowAt: rightIndex)
        setSelectCellClosure(rightCell, index: rightIndex)
        rightCell.frame = CGRect(origin: rightPoint, size: CGSize(width: rowWidth, height: bounds.height))
        scrollView.addSubview(rightCell)
        showCellMaxX = rightCell.frame.maxX
        addCellToShowQueue(rightCell)
        
        autoSlideIfNeeded()
    }
    
    private lazy var width = bounds.width
    private lazy var space = (width-rowWidth-2*rowSpace)/2
    private lazy var itemWidth = rowWidth+rowSpace
    private lazy var itemOutSpace = rowSpace/2+space
    private lazy var initCellPoint = CGPoint(x: CGFloat(10000)*CGFloat(pageControl.numberOfPages)*itemWidth+rowSpace/2, y: 0)
    private lazy var showCellMinX = initCellPoint.x
    private lazy var showCellMaxX = initCellPoint.x+rowWidth
    
    private var isNib = false
    private var reuseCellNibQueue: [String: UINib] = [:]
    private var reuseCellClassQueue: [String: CycleBannerViewCell.Type] = [:]
    
    // 正在显示的 cell
    private var cellOnShowQueue: [String: [CycleBannerViewCell]] = [:]
    // 重用池中的 cell
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
            // 先从重用池中拿取
            cell = reuseCell
        } else {
            // 重用池中没有，则根据 register 方式重新创建一个
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
    
    /// 在滚动时，如果出现新的空白区域，则从代理中获取相对应的 cell 来填充视图
    /// 用户在代理里面会通过 dequeueReusableCell withIdentifier: 方法来获取 cell
    /// 该方法本质是：先根据 identifier 从重用池中获取 cell
    /// 如果没有，则根据用户 register 的方式来重新生成一个 cell
    /// 判断左边两边是否多出空白区域，如果多出来，则加载 cell ，并修改 showCellMinX 和 showCellMaxX
    fileprivate func showCellsByContentOffset(_ contentOffset: CGPoint) {
        guard let dataSource = dataSource else {
            return
        }
        let screenLeft = contentOffset.x-itemOutSpace
        let screenRight = screenLeft + width
        if screenLeft < showCellMinX-rowSpace {
            // 左边多出空白区，加载 cell
            let newLeftCellX = showCellMinX-itemWidth
            let index = getIndexByContentOffset(CGPoint(x: newLeftCellX, y: initCellPoint.y))
            let newLeftCell = dataSource.cycleBannerView(self, cellForRowAt: index)
            setSelectCellClosure(newLeftCell, index: index)
            newLeftCell.frame = CGRect(origin: CGPoint(x: newLeftCellX, y: initCellPoint.y), size: CGSize(width: rowWidth, height: bounds.height))
            scrollView.addSubview(newLeftCell)
            addCellToShowQueue(newLeftCell)
            // 左边多出空白区域并用 cell 来填充后，设定 showCellMinX 为新 cell 的 minX
            showCellMinX = newLeftCell.frame.minX
        }
        if showCellMaxX+rowSpace < screenRight {
            // 右边多出空白区，加载 cell
            let newRightCellX = showCellMaxX+rowSpace
            let index = getIndexByContentOffset(CGPoint(x: newRightCellX, y: initCellPoint.y))
            let newRightCell = dataSource.cycleBannerView(self, cellForRowAt: index)
            setSelectCellClosure(newRightCell, index: index)
            newRightCell.frame = CGRect(origin: CGPoint(x: newRightCellX, y: initCellPoint.y), size: CGSize(width: rowWidth, height: bounds.height))
            scrollView.addSubview(newRightCell)
            addCellToShowQueue(newRightCell)
            // 右边多出空白区域并用 cell 来填充后，设定 showCellMaxX 为新 cell 的 max
            showCellMaxX = newRightCell.frame.maxX
        }
    }
    
    /// 在滚动时，如果有 cell 滚出屏幕，则把对应的 cell 从视图中移除，并把该 cell 实例放入重用池
    /// 如果有 cell 被移出视图（肯定是最左边或最右边），则修改 showCellMinX 和 showCellMaxX
    fileprivate func showCellToReuseQueue(_ contentOffset: CGPoint) {
        let scrollViewShowMinX = contentOffset.x-itemOutSpace
        let scrollViewShowMaxX = scrollViewShowMinX+width+itemOutSpace
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
                        reuseCellQueue[identifier]?.append(cell)
                    }
                }
            }
        }
        guard isModify else {
            return
        }
        // 修改 showCellMinX showCellMaxX
        _ = cellOnShowQueue.values.map { cells -> Void in
            guard cells.count > 0 else {
                return
            }
            var minX: CGFloat = cells.first!.frame.minX
            var maxX: CGFloat = cells.first!.frame.maxX
            _ = cells.map({ cell -> Void in
                if cell.frame.minX < minX {
                    minX = cell.frame.minX
                }
                if cell.frame.maxX > maxX {
                    maxX = cell.frame.maxX
                }
            })
            showCellMinX = minX
            showCellMaxX = maxX
        }
    }
    
    /// 停止滚动后，设置底部 pageControl 当前页面
    fileprivate func setCurrentPageByContentOffset(_ contentOffset: CGPoint) {
        let index = getIndexByContentOffset(contentOffset)
        pageControl.currentPage = index
    }
    
    /// contentOffset 为经过精确计算的cell的左上角坐标
    private func getIndexByContentOffset(_ contentOffset: CGPoint) -> Int {
        let offsetInWheel = contentOffset.x.truncatingRemainder(dividingBy: CGFloat(pageControl.numberOfPages)*itemWidth)
        // 由于 contentOffset 是经过精确计算而传过来的值，下面的除法操作，是不会存在余数的情况
        // 当然 index 可能达到 pageControl.numberOfPages 值，然而这是不允许的
        // 所以 index 需要对 pageControl.numberOfPages 取余
        var index = Int(offsetInWheel/itemWidth)
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

