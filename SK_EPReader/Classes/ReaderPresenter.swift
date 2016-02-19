//
//  ReaderPresenter.swift
//  SK_EPReader
//
//  Created by Yury Lapitsky on 20.02.16.
//  Copyright © 2016 skyylex. All rights reserved.
//

import Foundation
import UIKit

@objc protocol EpubRenderer: NSObjectProtocol {
    func webviewFrame() -> CGRect
    func updateCurrentPageLabel(text: String)
    func chapterDelegate() -> ChapterDelegate
}

class ReaderPresenter: NSObject {
    var epubLoaded = false
    var paginating = false
    
    var currentSpineIndex: Int = 0
    var currentPageInSpineIndex: Int = 0
    var pagesInCurrentSpineCount: Int = 0
    var currentTextSize: Int = 0
    var totalPagesCount: Int = 0
    
    var loadedEpub: EPub?
    
    var renderer: EpubRenderer?
    
    func globalPageCount() -> Int {
        var pageCount = Int(0)
        for index in 0...loadedEpub!.spineArray.count {
            if index < self.currentSpineIndex {
                if let chapter = loadedEpub?.spineArray[index] as? Chapter {
                    pageCount += chapter.pageCount
                }
            } else {
                break
            }
        }
        
        return pageCount
    }
    
    func calculateSliderPosition() -> Float {
        return Float(100.0) * Float(globalPageCount()) / Float(totalPagesCount)
    }
    
    // MARK: Pagination
    
    func updatePagination() {
        assert(renderer != nil, "updatePagination no renderer")
        
        if epubLoaded == true && paginating == false {
            print("Pagination Started!");
            
            paginating = true
            totalPagesCount = 0;
            
            if let chapter = loadedEpub!.spineArray.first as? Chapter, epubRenderer = renderer {
                let frame = epubRenderer.webviewFrame()
                let delegate = epubRenderer.chapterDelegate()
                chapter.load(frame, fontPercentSize:currentTextSize, delegate: delegate)
                epubRenderer.updateCurrentPageLabel("?/?")
            }
            
        }
    }
}

/*
- (NSUInteger)getGlobalPageCount{
__block NSUInteger pageCount = 0;

[self.loadedEpub.spineArray enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
if (idx < self.presenter.currentSpineIndex) {
pageCount += [currentChapter pageCount];
}
else {
*stop = YES;
}
}];

pageCount += self.presenter.currentPageInSpineIndex + 1;
return pageCount;
}
*/