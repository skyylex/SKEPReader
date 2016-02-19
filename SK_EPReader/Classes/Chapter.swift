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
    var fontPercentSize: Int = 100
    var spinePath: String = ""
    var title: String = ""
    var text: String = ""
    
    var windowSize: CGRect = CGRect()
    
    /// TODO: remove from here, chapter needs to be PO
    var delegate: ChapterDelegate?
    
    private var webView: UIWebView?
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
    
    func load(size: CGRect, fontPercentSize: Int) {
        self.fontPercentSize = fontPercentSize
        windowSize = size
        
        webView = UIWebView(frame: windowSize)
        webView!.delegate = self
        let request = NSURLRequest(URL: NSURL(fileURLWithPath: spinePath))
        webView!.loadRequest(request)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let varMySheetJS = "var mySheet = document.styleSheets[0];"
        
        var addCSSRuleJS = "function addCSSRule(selector, newRule) {"
        addCSSRuleJS += "if (mySheet.addRule) {"
        addCSSRuleJS += "mySheet.addRule(selector, newRule);"								// For Internet Explorer
        addCSSRuleJS += "} else {"
        addCSSRuleJS += "ruleIndex = mySheet.cssRules.length;"
        addCSSRuleJS += "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
        addCSSRuleJS += "}"
        addCSSRuleJS += "}"
        
        let columnSizesJS = String(format: "addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.height, webView.frame.width)
        let paragraphTextAlignJS = "addCSSRule('p', 'text-align: justify;')"
        let bodyTextAdjustJS = String(format: "addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", fontPercentSize)
        
        webView.stringByEvaluatingJavaScriptFromString(varMySheetJS)
        webView.stringByEvaluatingJavaScriptFromString(addCSSRuleJS)
        webView.stringByEvaluatingJavaScriptFromString(columnSizesJS)
        webView.stringByEvaluatingJavaScriptFromString(paragraphTextAlignJS)
        webView.stringByEvaluatingJavaScriptFromString(bodyTextAdjustJS)
        
        let result = webView.stringByEvaluatingJavaScriptFromString("document.documentElement.scrollWidth")
        if let pageCount = Int(result!) {
            self.pageCount = (webView.bounds.size.width != 0) ? Int(CGFloat(pageCount) / webView.bounds.size.width) : 0;
            
            self.webView = nil
            
            self.delegate?.chapterDidFinishLoad(self)
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print(error)
    }
}