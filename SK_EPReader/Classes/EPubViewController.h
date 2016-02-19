//
//  DetailViewController.h
//  AePubReader
//
//  Created by Federico Frappi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZipArchive.h"
#import "EPub.h"
#import "WYPopoverController.h"
#import "SK_EPReader-Swift.h"

@class SearchResultsViewController;
@class SearchResult;

static NSString *const EPubViewControllerStoryboardId = @"EPubViewControllerStoryboardId";

@interface EPubViewController : UIViewController <UIWebViewDelegate, ChapterDelegate, UISearchBarDelegate>

- (void)loadSpine:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex highlightSearchResult:(SearchResult *)theResult;

- (void)loadEpub:(NSURL*) epubURL;

@property (nonatomic, strong, readonly) EPub* loadedEpub;

@property (nonatomic, strong) SearchResult* currentSearchResult;

@property (nonatomic, assign) BOOL searching;

@end
