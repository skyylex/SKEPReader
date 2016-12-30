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

#define kMinTextSize 50
#define kMaxTextSize 200
#define kChangeTextStep 25

@interface EPubViewController()

@property (nonatomic, strong) ChapterLoader *loader;

@end

@implementation EPubViewController

#pragma mark - Loading

- (void)loadEpub:(NSURL *)epubURL{
    currentChapterIndex = 0;
    pageOffsetInChapter = 0;
    pagesInCurrentSpineCount = 0;
    totalPagesCount = 0;
	self.searching = NO;
    
    self.epubLoaded = NO;
    self.loadedEpub = [[EPub alloc] initWithEPubPath:[epubURL path]];
    self.epubLoaded = YES;
    
    NSLog(@"loadEpub");
	[self updatePagination];
}

#pragma mark - ChapterDelegate

- (void)chapterDidFinishLoad:(Chapter *)chapter{
    totalPagesCount += chapter.pageCount;

	if (chapter.chapterIndex + 1 < self.loadedEpub.chapters.count) {
        Chapter *currentChapter = self.loadedEpub.chapters[chapter.chapterIndex + 1];
        
        self.loader = [[ChapterLoader alloc] initWithChapter:currentChapter];
        self.loader.delegate = self;
        [self.loader loadChapterWithWindowSize:self.webView.bounds fontPercentSize:currentTextSize];

		[self setPageLabelForAmountOnly];
	} else {
		[self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
		self.paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

#pragma mark - Chapters

- (void)loadChapter:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex {
	[self loadChapter:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)loadChapter:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex highlightSearchResult:(SearchResult*)theResult{
	self.webView.hidden = YES;
	self.currentSearchResult = theResult;

	[chaptersPopover dismissPopoverAnimated:YES];
	[searchResultsPopover dismissPopoverAnimated:YES];
	
    Chapter *chapter = self.loadedEpub.chapters[spineIndex];
	NSURL *url = [NSURL fileURLWithPath:chapter.spinePath];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	
    pageOffsetInChapter = pageIndex;
	currentChapterIndex = spineIndex;
	
    if (!self.paginating){
        [self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
	}
}


#pragma mark - Navigation

// Current position checkers
- (BOOL)canMoveToNextChapter {
    return (self.paginating == NO) && (currentChapterIndex + 1 < self.loadedEpub.chapters.count);
}

- (BOOL)canMoveToPreviousChapter {
    return (self.paginating == NO) && (currentChapterIndex > 0);
}

// Inside chapter
- (BOOL)canMoveToNextPage {
    return (self.paginating == NO) && (pageOffsetInChapter + 1 < pagesInCurrentSpineCount);
}

// Inside chapter
- (BOOL)canMoveToPreviousPage {
    return (self.paginating == NO) && (pageOffsetInChapter > 0);
}

// Actual movement
- (void)moveToNextChapter {
    if (self.canMoveToNextChapter) {
        currentChapterIndex = currentChapterIndex + 1;
        [self loadChapter:currentChapterIndex atPageIndex:0];
	}
}

- (void)moveToPreviousChapter {
    if (self.canMoveToPreviousChapter) {
        currentChapterIndex = currentChapterIndex - 1;
        Chapter *chapter = self.loadedEpub.chapters[currentChapterIndex];
        [self loadChapter:currentChapterIndex atPageIndex:chapter.pageCount - 1];
	}
}

- (void)moveToNextPage {
	if (self.canMoveToNextPage) {
        pageOffsetInChapter = pageOffsetInChapter + 1;
        [self moveToPageInCurrentChapter:pageOffsetInChapter];
    } else if (self.canMoveToNextChapter) {
        [self moveToNextChapter];
	}
}

- (void)moveToPreviousPage {
	if (self.canMoveToPreviousPage) {
        pageOffsetInChapter = pageOffsetInChapter - 1;
        [self moveToPageInCurrentChapter:pageOffsetInChapter];
    } else if (self.canMoveToPreviousChapter) {
        [self moveToPreviousChapter];
	}
}

- (void)moveToPageInCurrentChapter:(NSUInteger)pageIndex {
    if (pageIndex >= pagesInCurrentSpineCount){
        pageIndex = pagesInCurrentSpineCount - 1;
        pageOffsetInChapter = pagesInCurrentSpineCount - 1;
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
    NSString *text = [NSString stringWithFormat:@"?/%d", totalPagesCount];
    [self.currentPageLabel setText:text];
}

- (void)setPageLabelForAmountAndIndex {
    NSString *text = [NSString stringWithFormat:@"%d/%d", self.calculateCurrentPageInBook, totalPagesCount];
    [self.currentPageLabel setText:text];
}

#pragma mark - Pagination

- (NSUInteger)calculateCurrentPageInBook {
    __block NSUInteger previousChapterPages = 0;
    NSArray *chapters = self.loadedEpub.chapters;
    
    // TODO: Could be cached for "heavy" books with a lot of chapters (as offset for each book)
    [chapters enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        if (idx < currentChapterIndex) {
            previousChapterPages += currentChapter.pageCount;
        } else {
            *stop = YES;
        }
    }];
    
    return previousChapterPages + pageOffsetInChapter + 1;
}

- (void)updatePagination{
    if (self.epubLoaded){
        if (!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            totalPagesCount = 0;
            
            [self loadChapter:currentChapterIndex atPageIndex:pageOffsetInChapter];
            
            Chapter *chapter = self.loadedEpub.chapters.firstObject;
            if (chapter != nil) {
                self.loader = [[ChapterLoader alloc] initWithChapter:chapter];
                self.loader.delegate = self;
                [self.loader loadChapterWithWindowSize:self.webView.bounds fontPercentSize:currentTextSize];
                
                [self.currentPageLabel setText:@"?/?"];
            }
        }
    }
}

#pragma mark - Event-based methods

- (void)onTextSizeIncreased {
    if (currentTextSize == kMaxTextSize){
        [self.incTextSizeButton setEnabled:NO];
    }
    [self.decTextSizeButton setEnabled:YES];
    
    [self onTextSizeChanged];
}

- (void)onTextSizeDecreased {
    if (currentTextSize == kMinTextSize) {
        [self.decTextSizeButton setEnabled:NO];
    }
    
    [self.incTextSizeButton setEnabled:YES];
    
    [self onTextSizeChanged];
}

- (void)onTextSizeChanged {
    [self updatePagination];
}

#pragma mark - IBAction

- (IBAction)increaseTextSizeClicked:(id)sender{
	if (!self.paginating){
		if (currentTextSize + kChangeTextStep <= kMaxTextSize){
			currentTextSize += kChangeTextStep;
			
            [self onTextSizeIncreased];
		}
	}
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.paginating){
		if (currentTextSize - kChangeTextStep >= kMinTextSize) {
			currentTextSize -= kChangeTextStep;
        
            [self onTextSizeDecreased];
		}
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (!searchResultsPopover) {
        searchResultsPopover = [[WYPopoverController alloc] initWithContentViewController:searchResViewController];
        [searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    if (![searchResultsPopover isPopoverVisible]) {
        [searchResultsPopover presentPopoverFromRect:searchBar.bounds
                                              inView:searchBar
                            permittedArrowDirections:WYPopoverArrowDirectionAny
                                            animated:YES];
    }
    
    if (!self.searching){
        self.searching = YES;
        [searchResViewController searchString:[searchBar text]];
        [searchBar resignFirstResponder];
    }
}

- (IBAction)showChapterIndex:(id)sender {
    if (!chaptersPopover) {
        ChapterListViewController *chapterListView = [ChapterListViewController new];
        [chapterListView setEpubViewController:self];
        chaptersPopover = [[WYPopoverController alloc] initWithContentViewController:chapterListView];
        [chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    if ([chaptersPopover isPopoverVisible]) {
        [chaptersPopover dismissPopoverAnimated:YES];
    }
    else {
        [chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton
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
    NSAssert(totalPagesCount > 0, @"No pages in the book");
    
    int presentedFirstPage = 1;
    int presentedLastPage = totalPagesCount;
    if (self.pageSlider.minimumValue != presentedFirstPage) {
        self.pageSlider.minimumValue = presentedFirstPage;
    }
    
    if (self.pageSlider.maximumValue != (float)presentedLastPage) {
        self.pageSlider.maximumValue = (float)presentedLastPage;
    }
}

- (void)updateSliderValue {
    NSUInteger currentPageInBook = [self calculateCurrentPageInBook];
    if (currentPageInBook == 0 || currentPageInBook >= totalPagesCount) { return; }
    
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
    
    NSString *text = [NSString stringWithFormat:@"%d/%d", targetPage, totalPagesCount];
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
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", currentTextSize];
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
    
    float totalWidth = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] floatValue];
    pagesInCurrentSpineCount = (NSUInteger)(totalWidth / self.webView.bounds.size.width);
    
    [self moveToPageInCurrentChapter:pageOffsetInChapter];
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
    currentTextSize = 100;
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
