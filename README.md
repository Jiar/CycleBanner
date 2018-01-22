# CycleBanner
Infinite horizontal scrolling control.

<p align="center">

<img src="https://github.com/Jiar/CycleBanner/blob/master/Screenshot/CycleBanner_Main.gif?raw=true" alt="CycleBanner" title="CycleBanner"/>

</p>

## Requirements

- iOS 9.0+
- Xcode 9.0+
- Swift 4.0+

## CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build CycleBanner 1.0

To integrate CycleBanner into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CycleBanner', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

```swift

import UIKit
import CycleBanner

class ViewController: UIViewController {

    @IBOutlet weak var cycleBannerView: CycleBannerView!
    fileprivate var cycleBannerCount = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cycleBannerView.register(UINib(nibName: "CustomCycleBannerViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        let space: CGFloat = 10
        let rowSpace: CGFloat = 10
        cycleBannerView.rowSpace = rowSpace
        cycleBannerView.rowWidth = view.bounds.width-2*(space+rowSpace)
        cycleBannerView.timeInterval = 3
        cycleBannerView.autoSlide = true
        cycleBannerView.isHiddenPageControl = false
        cycleBannerView.delegate = self
        cycleBannerView.dataSource = self
        cycleBannerView.reloadData()
    }
}

extension ViewController: CycleBannerViewDataSource {
    
    func numberOfBanners(in cycleBannerView: CycleBannerView) -> Int {
        return cycleBannerCount
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


```

## License

CycleBanner is released under the Apache-2.0 license. See LICENSE for details.

