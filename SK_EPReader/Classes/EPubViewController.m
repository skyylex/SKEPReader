//
//  DetailViewController.m
//  AePubReader
//
//  Created by Federico Frappi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EPubViewController.h"
#import "ChapterListViewController.h"
#import "SearchResultsViewController.h"
#import "SearchResult.h"
#import "UIWebView+SearchWebView.h"
#import "Chapter.h"
#import "ChapterLoader.h"

@interface EPubViewController()

@property (nonatomic, strong) ChapterLoader *loader;

@property (nonatomic, strong) WYPopoverController *chaptersPopover;
@property (nonatomic, strong) WYPopoverController *searchResultsPopover;

@property (nonatomic, strong) SearchResultsViewController* searchResViewController;

@end

@implementation EPubViewController

#pragma mark - Loading

- (void)loadEpub:(NSURL *)epubURL{
    self.readingState = [ReadingState blankState];
    
	self.searching = NO;
    
    self.epubLoaded = NO;
    self.loadedEpub = [[EPub alloc] initWithEPubPath:[epubURL path]];
    self.epubLoaded = YES;
    
    NSLog(@"Book was loaded at: %@", self.loadedEpub.epubFilePath);
	[self updatePagination];
}

#pragma mark - ChapterDelegate

- (void)chapterDidFinishLoad:(Chapter *)chapter{
    self.readingState.total += chapter.pageCount;

	if (chapter.chapterIndex + 1 < self.loadedEpub.chapters.count) {
        NSLog(@"Chapter %d processing was launched.", chapter.chapterIndex);
        
        Chapter *currentChapter = self.loadedEpub.chapters[chapter.chapterIndex + 1];
        int textSize = self.readingState.textSize;
        
        self.loader = [[ChapterLoader alloc] initWithChapter:currentChapter];
        self.loader.delegate = self;
        [self.loader loadChapterWithWindowSize:self.webView.bounds fontPercentSize:textSize];

		[self setPageLabelForAmountOnly];
	} else {
        self.paginating = NO;
        NSLog(@"Processing was finished.");
        
		[self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
		
        [self loadChapter:self.readingState.chapterIndex atPageIndex:self.readingState.pageInChapter];
	}
}

#pragma mark - Chapters

- (void)loadChapter:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex {
	[self loadChapter:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)loadChapter:(NSUInteger)chapterIndex atPageIndex:(NSUInteger)pageIndex highlightSearchResult:(SearchResult *)theResult {
	self.webView.hidden = YES;
	self.currentSearchResult = theResult;

	[self.chaptersPopover dismissPopoverAnimated:YES];
	[self.searchResultsPopover dismissPopoverAnimated:YES];
	
    Chapter *chapter = self.loadedEpub.chapters[chapterIndex];
	NSURL *url = [NSURL fileURLWithPath:chapter.spinePath];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	
    self.readingState.pageInChapter = pageIndex;
	self.readingState.chapterIndex = chapterIndex;
	
    if (!self.paginating){
        [self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
	}
}


#pragma mark - Navigation

// Current position checkers
- (BOOL)canMoveToNextChapter {
    return (self.paginating == NO) && (self.readingState.chapterIndex + 1 < self.loadedEpub.chapters.count);
}

- (BOOL)canMoveToPreviousChapter {
    return (self.paginating == NO) && (self.readingState.chapterIndex > 0);
}

// Inside chapter
- (BOOL)canMoveToNextPage {
    Chapter *chapter = self.loadedEpub.chapters[self.readingState.chapterIndex];
    return (self.paginating == NO) && (self.readingState.pageInChapter + 1 < chapter.pageCount);
}

// Inside chapter
- (BOOL)canMoveToPreviousPage {
    return (self.paginating == NO) && (self.readingState.pageInChapter > 0);
}

// Actual movement
- (void)moveToNextChapter {
    if (self.canMoveToNextChapter) {
        self.readingState.chapterIndex = self.readingState.chapterIndex + 1;
        [self loadChapter:self.readingState.chapterIndex atPageIndex:0];
	}
}

- (void)moveToPreviousChapter {
    if (self.canMoveToPreviousChapter) {
        self.readingState.chapterIndex = self.readingState.chapterIndex - 1;
        Chapter *chapter = self.loadedEpub.chapters[self.readingState.chapterIndex];
        [self loadChapter:self.readingState.chapterIndex atPageIndex:chapter.pageCount - 1];
	}
}

- (void)moveToNextPage {
	if (self.canMoveToNextPage) {
        self.readingState.pageInChapter = self.readingState.pageInChapter + 1;
        [self moveToPageInCurrentChapter:self.readingState.pageInChapter];
    } else if (self.canMoveToNextChapter) {
        [self moveToNextChapter];
	}
}

- (void)moveToPreviousPage {
	if (self.canMoveToPreviousPage) {
        self.readingState.pageInChapter = self.readingState.pageInChapter - 1;
        [self moveToPageInCurrentChapter:self.readingState.pageInChapter];
    } else if (self.canMoveToPreviousChapter) {
        [self moveToPreviousChapter];
	}
}

- (void)moveToPageInCurrentChapter:(NSUInteger)pageIndex {
    Chapter *chapter = self.loadedEpub.chapters[self.readingState.chapterIndex];
    if (pageIndex >= chapter.pageCount){
        pageIndex = chapter.pageCount - 1;
    }
    
    float pageOffset = pageIndex * self.webView.bounds.size.width;
    
    NSString *goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
    NSString *goTo = [NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
    
    [self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
    [self.webView stringByEvaluatingJavaScriptFromString:goTo];
    
    if (!self.paginating) {
        [self updateSliderValue];
        [self setPageLabelForAmountAndIndex];
    }
    
    self.webView.hidden = NO;
}

#pragma mark - Page Label

- (void)setPageLabelForAmountOnly {
    NSString *text = [NSString stringWithFormat:@"?/%d", self.readingState.total];
    [self.currentPageLabel setText:text];
}

- (void)setPageLabelForAmountAndIndex {
    NSString *text = [NSString stringWithFormat:@"%d/%d", self.calculateCurrentPageInBook, self.readingState.total];
    [self.currentPageLabel setText:text];
}

#pragma mark - Pagination

- (NSUInteger)calculateCurrentPageInBook {
    __block NSUInteger previousChapterPages = 0;
    NSArray *chapters = self.loadedEpub.chapters;
    
    // TODO: Could be cached for "heavy" books with a lot of chapters (as offset for each book)
    [chapters enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        if (idx < self.readingState.chapterIndex) {
            previousChapterPages += currentChapter.pageCount;
        } else {
            *stop = YES;
        }
    }];
    
    return previousChapterPages + self.readingState.pageInChapter + 1;
}

- (void)updatePagination{
    if (self.epubLoaded){
        if (!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            self.readingState.total = 0;
            
            Chapter *chapter = self.loadedEpub.chapters.firstObject;
            if (chapter != nil) {
                int textSize = self.readingState.textSize;
                
                self.loader = [[ChapterLoader alloc] initWithChapter:chapter];
                self.loader.delegate = self;
                [self.loader loadChapterWithWindowSize:self.webView.bounds fontPercentSize:textSize];
                
                [self.currentPageLabel setText:@"?/?"];
            }
        }
    }
}

#pragma mark - Event-based methods

- (void)onTextSizeIncreased {
    self.incTextSizeButton.enabled = self.readingState.canIncreaseFontSize;
    self.decTextSizeButton.enabled = YES;
    
    [self onTextSizeChanged];
}

- (void)onTextSizeDecreased {
    self.decTextSizeButton.enabled = self.readingState.canDecreaseFontSize;
    self.incTextSizeButton.enabled = YES;
    
    [self onTextSizeChanged];
}

- (void)onTextSizeChanged {
    [self updatePagination];
}

#pragma mark - IBAction

- (IBAction)increaseTextSizeClicked:(id)sender{
	if (self.paginating == YES) { return; }
    
    if (self.readingState.canIncreaseFontSize){
        [self.readingState increaseFontOnStep];
        
        [self onTextSizeIncreased];
    }
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
    if (self.paginating == YES) { return; }
    
    if (self.readingState.canDecreaseFontSize) {
        [self.readingState increaseFontOnStep];
    
        [self onTextSizeDecreased];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (self.searchResultsPopover == nil) {
        self.searchResultsPopover = [[WYPopoverController alloc] initWithContentViewController:self.searchResViewController];
        [self.searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    
    if (self.searchResultsPopover.isPopoverVisible == NO) {
        [self.searchResultsPopover presentPopoverFromRect:searchBar.bounds
                                              inView:searchBar
                            permittedArrowDirections:WYPopoverArrowDirectionAny
                                            animated:YES];
    }
    
    if (self.searching == NO){
        self.searching = YES;
        [self.searchResViewController searchString:searchBar.text];
        [searchBar resignFirstResponder];
    }
}

- (IBAction)showChapterIndex:(id)sender {
    if (self.chaptersPopover == nil) {
        ChapterListViewController *chapterListView = [ChapterListViewController new];
        [chapterListView setEpubViewController:self];
        self.chaptersPopover = [[WYPopoverController alloc] initWithContentViewController:chapterListView];
        [self.chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    
    if (self.chaptersPopover.isPopoverVisible) {
        [self.chaptersPopover dismissPopoverAnimated:YES];
    } else {
        [self.chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton
                                permittedArrowDirections:WYPopoverArrowDirectionAny
                                                animated:YES];
    }
}


#pragma mark - Page slider

/// Real pages range [0 - (pages_count - 1)]
/// Presented in reader pages [1 - #(pages_count)]
/// So it's shifted (presented_page_number = real_page_number + 1) to be more natural

- (void)updateSliderLimits {
    NSAssert(self.pageSlider != nil, @"Page slider is nil");
    NSAssert(self.readingState.total > 0, @"No pages in the book");
    
    int presentedFirstPage = 1;
    int presentedLastPage = self.readingState.total;
    if (self.pageSlider.minimumValue != presentedFirstPage) {
        self.pageSlider.minimumValue = presentedFirstPage;
    }
    
    if (self.pageSlider.maximumValue != (float)presentedLastPage) {
        self.pageSlider.maximumValue = (float)presentedLastPage;
    }
}

- (void)updateSliderValue {
    NSUInteger currentPageInBook = [self calculateCurrentPageInBook];
    if (currentPageInBook == 0 || currentPageInBook >= self.readingState.total) { return; }
    
    /// Not the best place to update limits, but the most stable way to ensure that
    /// slider has proper max-min borders
    [self updateSliderLimits];
    [self.pageSlider setValue:currentPageInBook animated:YES];
}

- (NSUInteger)currentSliderPage {
    NSUInteger currentSliderPage = (NSUInteger)(self.pageSlider.value);
    return currentSliderPage;
}

- (IBAction)slidingStarted:(id)sender {
    NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage = 1;
    }
    
    NSString *text = [NSString stringWithFormat:@"%d/%d", targetPage, self.readingState.total];
	[self.currentPageLabel setText:text];
}

- (IBAction)slidingEnded:(id)sender {
	NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage = 1;
    }
	
    __block NSUInteger pageSum = 0;
    __block NSUInteger chapterIndex = 0;
    __block NSUInteger pageIndex = 0;
    
    [self.loadedEpub.chapters enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        pageSum += [currentChapter pageCount];
        if (pageSum >= targetPage) {
            pageIndex = [currentChapter pageCount] - 1 - pageSum + targetPage;
            chapterIndex = idx;
            *stop = YES;
        }
    }];

	[self loadChapter:chapterIndex atPageIndex:pageIndex];
}

#pragma mark -
#pragma mark UIWebView

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView didFailLoadWithError: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView{
    
    NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
    
    NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
    "if (mySheet.addRule) {"
    "mySheet.addRule(selector, newRule);"								// For Internet Explorer
    "} else {"
    "ruleIndex = mySheet.cssRules.length;"
    "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
    "}"
    "}";
    
    NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", self.webView.frame.size.height, self.webView.frame.size.width];
    NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.readingState.textSize];
    NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];
    
    
    [self.webView stringByEvaluatingJavaScriptFromString:varMySheet];
    [self.webView stringByEvaluatingJavaScriptFromString:addCSSRule];
    [self.webView stringByEvaluatingJavaScriptFromString:insertRule1];
    [self.webView stringByEvaluatingJavaScriptFromString:insertRule2];
    [self.webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    [self.webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
    
    if (self.currentSearchResult) {
        [self.webView highlightAllOccurencesOfString:self.currentSearchResult.originatingQuery];
    }
    
    [self moveToPageInCurrentChapter:self.readingState.pageInChapter];
}

#pragma mark - Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSLog(@"shouldAutorotate");
    [self updatePagination];
	return YES;
}

#pragma mark - UIViewController Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareWebview];
    [self prepareGestures];
    [self prepareSubscriptions];
    [self prepareDisplaySettings];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Prepare

- (void)prepareDisplaySettings {
    
}

- (void)prepareSubscriptions {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePagination)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)prepareWebview {
    [self.webView setDelegate:self];
    
    [self prepareScrollView];
}

- (void)prepareScrollView {
    UIScrollView *scrollView = nil;
    for (UIView *subview in self.webView.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]){
            scrollView = (UIScrollView *)subview;
            scrollView.scrollEnabled = NO;
            scrollView.bounces = NO;
        }
    }
}

- (void)prepareGestures {
    SEL rightAction = @selector(moveToNextPage);
    SEL leftAction = @selector(moveToPreviousPage);
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                action:rightAction];
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                               action:leftAction];
    [left setDirection:UISwipeGestureRecognizerDirectionRight];
    [right setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    [self.webView addGestureRecognizer:right];
    [self.webView addGestureRecognizer:left];
}

@end
