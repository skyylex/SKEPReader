//
//  ReaderPresenter.swift
//  SK_EPReader
//
//  Created by Yury Lapitsky on 20.02.16.
//  Copyright © 2016 skyylex. All rights reserved.
//

import Foundation

class ReaderPresenter: NSObject {
    var epubLoaded = false
    var paginating = false
//    var searching = false
    
    var currentSpineIndex: Int = 0
    var currentPageInSpineIndex: Int = 0
    var pagesInCurrentSpineCount: Int = 0
    var currentTextSize: Int = 0
    var totalPagesCount: Int = 0
    
    var loadedEpub: EPub?
}