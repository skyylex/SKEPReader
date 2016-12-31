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
#import "Chapter.h"
#import "WYPopoverController.h"
#import "ReadingState.h"

@class SearchResultsViewController;
@class SearchResult;

static NSString *const EPubViewControllerStoryboardId = @"EPubViewControllerStoryboardId";

@interface EPubViewController : UIViewController <UIWebViewDelegate, ChapterLoaderDelegate, UISearchBarDelegate>

- (IBAction)showChapterIndex:(id)sender;
- (IBAction)increaseTextSizeClicked:(id)sender;
- (IBAction)decreaseTextSizeClicked:(id)sender;
- (IBAction)slidingStarted:(id)sender;
- (IBAction)slidingEnded:(id)sender;

- (void)loadChapter:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex highlightSearchResult:(SearchResult *)theResult;

- (void)loadEpub:(NSURL*) epubURL;

@property (nonatomic, strong) ReadingState *readingState;

@property (nonatomic, strong) EPub* loadedEpub;

@property (nonatomic, strong) SearchResult* currentSearchResult;

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *chapterListButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *decTextSizeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *incTextSizeButton;

@property (nonatomic, strong) IBOutlet UISlider *pageSlider;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;

@property (nonatomic, assign) BOOL epubLoaded;
@property (nonatomic, assign) BOOL paginating;
@property (nonatomic, assign) BOOL searching;

@end
