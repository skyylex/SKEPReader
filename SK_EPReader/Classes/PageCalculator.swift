//
//  PageCalculator.swift
//  SK_EPReader
//
//  Created by Yury Lapitsky on 2/19/16.
//  Copyright © 2016 skyylex. All rights reserved.
//

import Foundation
import UIKit

class PageCalculator: NSObject, UIWebViewDelegate {
    private (set) var chapter: Chapter
    
    private let windowSize: CGRect
    private let fontPercentSize: Int
    private var pageCount: Int = 0
    private var calcWebView: UIWebView?
    private var delegate: ChapterDelegate
    
    init(size: CGRect, fontPercentSize:Int, chapter: Chapter, delegate: ChapterDelegate) {
        self.fontPercentSize = fontPercentSize
        self.delegate = delegate
        self.chapter = chapter
        self.windowSize = size
    }
    
    // MARK: Calculate
    func calculate() {
        calcWebView = UIWebView(frame: windowSize)
        calcWebView!.delegate = self
        let request = NSURLRequest(URL: NSURL(fileURLWithPath: chapter.spinePath))
        calcWebView!.loadRequest(request)
    }
    
    // MARK: UIWebView delegate
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
            chapter.pageCount = (webView.bounds.size.width != 0) ? Int(CGFloat(pageCount) / webView.bounds.size.width) : 0;
            
            calcWebView = nil
            
            delegate.chapterDidFinishLoad(self.chapter)
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print(error)
    }
}
