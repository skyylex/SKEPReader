//
//  Chapter.swift
//  SK_EPReader
//
//  Created by Yury Lapitsky on 2/19/16.
//  Copyright © 2016 skyylex. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ChapterDelegate: NSObjectProtocol {
    func chapterDidFinishLoad(chapter: Chapter)
}

// TODO: chapter should be struct
class Chapter: NSObject, UIWebViewDelegate {
     /// TODO: rename to index
    var chapterIndex: Int = 0
    var pageCount: Int = 0
    var spinePath: String = ""
    var title: String = ""
    var text: String = ""
    
    private var webView: UIWebView?
    private var pageCalculator: PageCalculator?
}

extension Chapter {
    convenience init(spinePath: String, title: String, chapterIndex: Int) {
        self.init()
        
        self.spinePath = spinePath
        self.title = title
        self.chapterIndex = chapterIndex
            
        let spineData =  NSData(contentsOfURL:NSURL(fileURLWithPath: spinePath))
        /// TODO: force unwrap need to be replaced with validation before creation
        self.text = NSString(data:spineData!, encoding:NSUTF8StringEncoding) as! String
    }
    
    func load(size: CGRect, fontPercentSize: Int, delegate: ChapterDelegate) {
        pageCalculator = PageCalculator(size: size, fontPercentSize:fontPercentSize, chapter: self, delegate: delegate)
        pageCalculator?.calculate()
    }
}