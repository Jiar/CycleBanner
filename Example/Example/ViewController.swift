//
//  ViewController.swift
//  Example
//
//  Created by Jiar on 2017/12/18.
//  Copyright © 2017年 Jiar. All rights reserved.
//

import UIKit
import CycleBanner

class ViewController: UIViewController {

    @IBOutlet weak var cycleBannerView: CycleBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cycleBannerView.register(UINib(nibName: "CustomCycleBannerViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        cycleBannerView.delegate = self
        cycleBannerView.dataSource = self
        cycleBannerView.reloadData()
    }

}

extension ViewController: CycleBannerViewDataSource {
    
    func numberOfBanners(in cycleBannerView: CycleBannerView) -> Int {
        return 8
    }
    
    func cycleBannerView(_ cycleBannerView: CycleBannerView, cellForRowAt index: Int) -> CycleBannerViewCell {
        let cell = cycleBannerView.dequeueReusableCell(withIdentifier: "Cell") as! CustomCycleBannerViewCell
        cell.config("\(index)")
        return cell
    }
    
}

extension ViewController: CycleBannerViewDelegate {
    
    func cycleBannerView(_ cycleBannerView: CycleBannerView, didSelectRowAt index: Int) {
        print("select at: \(index)")
    }
    
}
