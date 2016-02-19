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
#import "SK_EPReader-Swift.h"

#define kMinTextSize 50
#define kMaxTextSize 200
#define kChangeTextStep 25

@interface EPubViewController()

@property (nonatomic, assign) NSUInteger currentSpineIndex;
@property (nonatomic, assign) NSUInteger currentPageInSpineIndex;
@property (nonatomic, assign) NSUInteger pagesInCurrentSpineCount;
@property (nonatomic, assign) NSUInteger currentTextSize;
@property (nonatomic, assign) NSUInteger totalPagesCount;

@property (nonatomic, strong) WYPopoverController *chaptersPopover;
@property (nonatomic, strong) WYPopoverController *searchResultsPopover;

@property (nonatomic, strong) SearchResultsViewController* searchResViewController;

@property (nonatomic, strong) ReaderPresenter *presenter;

@end

@implementation EPubViewController

#pragma mark -

- (void)loadEpub:(NSURL *)epubURL{
    self.currentSpineIndex = 0;
    self.currentPageInSpineIndex = 0;
    self.pagesInCurrentSpineCount = 0;
    self.totalPagesCount = 0;
	self.searching = NO;
    
    self.epubLoaded = NO;
    self.loadedEpub = [[EPub alloc] initWithEPubPath:[epubURL path]];
    self.epubLoaded = YES;
    
    NSLog(@"loadEpub");
	[self updatePagination];
}

#pragma mark -
#pragma mark ChapterDelegate

- (void)chapterDidFinishLoad:(Chapter *)chapter{
    self.totalPagesCount += chapter.pageCount;

	if (chapter.chapterIndex + 1 < [self.loadedEpub.spineArray count]) {
        Chapter *currentChapter = self.loadedEpub.spineArray[chapter.chapterIndex + 1];
        [currentChapter load:self.webView.bounds fontPercentSize:self.currentTextSize delegate:self];
		[self setPageLabelForAmountOnly];
	} else {
		[self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
		self.paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

#pragma mark -
#pragma mark Spine

- (void)loadSpine:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)loadSpine:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex highlightSearchResult:(SearchResult*)theResult{
	self.webView.hidden = YES;
	self.currentSearchResult = theResult;

	[self.chaptersPopover dismissPopoverAnimated:YES];
	[self.searchResultsPopover dismissPopoverAnimated:YES];
	
	NSURL *url = [NSURL fileURLWithPath:[[self.loadedEpub.spineArray objectAtIndex:spineIndex] spinePath]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	
    self.currentPageInSpineIndex = pageIndex;
	self.currentSpineIndex = spineIndex;
	
    if (!self.paginating){
        [self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
	}
}


#pragma mark -
#pragma mark Navigation

- (void)gotoPageInCurrentSpine:(NSUInteger)pageIndex {
	if (pageIndex >= self.pagesInCurrentSpineCount){
		pageIndex = self.pagesInCurrentSpineCount - 1;
		self.currentPageInSpineIndex = self.pagesInCurrentSpineCount - 1;
	}
	
	float pageOffset = pageIndex * self.webView.bounds.size.width;

	NSString *goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString *goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[self.webView stringByEvaluatingJavaScriptFromString:goTo];
	
	if (!self.paginating) {
		[self updateSliderValue];
	}
	
	self.webView.hidden = NO;
}

- (void)gotoNextSpine {
	if (!self.paginating) {
		if (self.currentSpineIndex + 1 < [self.loadedEpub.spineArray count]) {
			[self loadSpine:++self.currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoPrevSpine {
	if (!self.paginating){
		if ((int)(self.currentSpineIndex - 1) >= 0){
			[self loadSpine:--self.currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoNextPage {
	if (!self.paginating){
		if(self.currentPageInSpineIndex + 1 < self.pagesInCurrentSpineCount){
			[self gotoPageInCurrentSpine:++self.currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}		
	}
}

- (void)gotoPrevPage {
	if (!self.paginating) {
		if ((int)(self.currentSpineIndex - 1) >= 0){
			[self gotoPageInCurrentSpine:--self.currentPageInSpineIndex];
		} else {
			if (self.currentSpineIndex != 0){
                Chapter *currentChapter = self.loadedEpub.spineArray[self.currentSpineIndex - 1];
				NSUInteger targetPage = [currentChapter pageCount];
				[self loadSpine:--self.currentSpineIndex atPageIndex:targetPage - 1];
			}
		}
	}
}

#pragma mark -
#pragma mark Page Label

- (void)setPageLabelForAmountOnly {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"?/%ld", self.totalPagesCount]];
}

- (void)setPageLabelForAmountAndIndex {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", [self getGlobalPageCount], self.totalPagesCount]];
}

#pragma mark -
#pragma mark Pagination

- (NSUInteger)getGlobalPageCount{
    __block NSUInteger pageCount = 0;
    
    [self.loadedEpub.spineArray enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        if (idx < self.currentSpineIndex) {
            pageCount += [currentChapter pageCount];
        }
        else {
            *stop = YES;
        }
    }];
    
    pageCount += self.currentPageInSpineIndex + 1;
    return pageCount;
}

- (void)updatePagination{
    if (self.epubLoaded){
        if (!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            self.totalPagesCount = 0;
            
            [self loadSpine:self.currentSpineIndex atPageIndex:self.currentPageInSpineIndex];
            
            Chapter *chapter = self.loadedEpub.spineArray[0];
            
            [chapter load:self.webView.bounds fontPercentSize:self.currentTextSize delegate:self];
            [self.currentPageLabel setText:@"?/?"];
        }
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)increaseTextSizeClicked:(id)sender{
	if (!self.paginating){
		if (self.currentTextSize + kChangeTextStep <= kMaxTextSize){
			self.currentTextSize += kChangeTextStep;
			[self updatePagination];
			if (self.currentTextSize == kMaxTextSize){
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.paginating){
		if (self.currentTextSize - kChangeTextStep >= kMinTextSize) {
			self.currentTextSize -= kChangeTextStep;
			[self updatePagination];
			
            if (self.currentTextSize == kMinTextSize) {
				[self.decTextSizeButton setEnabled:NO];
			}
            
			[self.incTextSizeButton setEnabled:YES];
		}
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (!self.searchResultsPopover) {
        self.searchResultsPopover = [[WYPopoverController alloc] initWithContentViewController:self.searchResViewController];
        [self.searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    if (![self.searchResultsPopover isPopoverVisible]) {
        [self.searchResultsPopover presentPopoverFromRect:searchBar.bounds
                                              inView:searchBar
                            permittedArrowDirections:WYPopoverArrowDirectionAny
                                            animated:YES];
    }
    
    if (!self.searching){
        self.searching = YES;
        [self.searchResViewController searchString:[searchBar text]];
        [searchBar resignFirstResponder];
    }
}

- (IBAction)showChapterIndex:(id)sender {
    if (!self.chaptersPopover) {
        ChapterListViewController *chapterListView = [ChapterListViewController new];
        [chapterListView setEpubViewController:self];
        self.chaptersPopover = [[WYPopoverController alloc] initWithContentViewController:chapterListView];
        [self.chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
    }
    if ([self.chaptersPopover isPopoverVisible]) {
        [self.chaptersPopover dismissPopoverAnimated:YES];
    }
    else {
        [self.chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton
                                permittedArrowDirections:WYPopoverArrowDirectionAny
                                                animated:YES];
    }
}


#pragma mark -
#pragma mark Slider

- (void)updateSliderValue {
    [self.pageSlider setValue:100.0 * (float)[self getGlobalPageCount] / (float)self.totalPagesCount
                     animated:YES];
}

- (NSUInteger)currentSliderPage {
    NSUInteger currentSliderPage = (NSUInteger)((self.pageSlider.value / 100.0) * (float)self.totalPagesCount);
    return currentSliderPage;
}

- (IBAction)slidingStarted:(id)sender {
    NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage++;
    }
    
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", targetPage, self.totalPagesCount]];
}

- (IBAction)slidingEnded:(id)sender {
	NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage++;
    }
	
    __block NSUInteger pageSum = 0;
    __block NSUInteger chapterIndex = 0;
    __block NSUInteger pageIndex = 0;
    
    [self.loadedEpub.spineArray enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        pageSum += [currentChapter pageCount];
        if (pageSum >= targetPage) {
            pageIndex = [currentChapter pageCount] - 1 - pageSum + targetPage;
            chapterIndex = idx;
            *stop = YES;
        }
    }];

	[self loadSpine:chapterIndex atPageIndex:pageIndex];
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
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.currentTextSize];
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
    self.pagesInCurrentSpineCount = (NSUInteger)(totalWidth / self.webView.bounds.size.width);
    
    [self gotoPageInCurrentSpine:self.currentPageInSpineIndex];
}

#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSLog(@"shouldAutorotate");
    [self updatePagination];
	return YES;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark View lifecycle

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePagination)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
	[self.webView setDelegate:self];
		
	UIScrollView *sv = nil;
	for (UIView* v in self.webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
    
    [self connectGestures];
    
    self.currentTextSize = 100;
}

#pragma mark -
#pragma mark Gestures

- (void)connectGestures {
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(gotoNextPage)];
    [rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    UISwipeGestureRecognizer* leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(gotoPrevPage)];
    [leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    
    [self.webView addGestureRecognizer:rightSwipeRecognizer];
    [self.webView addGestureRecognizer:leftSwipeRecognizer];
}

@end
