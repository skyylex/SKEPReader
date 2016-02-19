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
    // State
    func webviewFrame() -> CGRect
    
    // Update
    func updateCurrentPageLabel(text: String)
    func updateSliderValue()
}

class ReaderPresenter: NSObject, ChapterDelegate {
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
                chapter.load(frame, fontPercentSize:currentTextSize, delegate:self)
                epubRenderer.updateCurrentPageLabel(pageTextForUndefinedState)
            }
            
        }
    }
    
    // MARK: ChapterDelegate
    
    func chapterDidFinishLoad(chapter: Chapter) {
        totalPagesCount += chapter.pageCount;
        
        if let aliveEpub = loadedEpub, aliveRenderer = renderer {
            if (chapter.chapterIndex + 1 < aliveEpub.spineArray.count) {
                if let currentChapter = aliveEpub.spineArray[chapter.chapterIndex + 1] as? Chapter {
                    currentChapter.load(aliveRenderer.webviewFrame(), fontPercentSize:currentTextSize, delegate:self)
                    aliveRenderer.updateCurrentPageLabel(pageTextForAmountOnly)
                }
            } else {
                aliveRenderer.updateCurrentPageLabel(pageTextForAmountAndIndex)
                aliveRenderer.updateSliderValue()
                paginating = false
                
                print("Pagination Ended!");
            }
        }
    }
    
    var pageTextForUndefinedState: String {
        return "?/?"
    }
    
    var pageTextForAmountOnly: String {
        return String(format:"?/%ld", totalPagesCount);
    }
    
    var pageTextForAmountAndIndex: String {
        return String(format:"%ld/%ld", globalPageCount(), totalPagesCount);
    }
}