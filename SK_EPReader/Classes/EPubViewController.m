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

#define kMinTextSize 50
#define kMaxTextSize 200
#define kChangeTextStep 25

@interface EPubViewController()

- (void)gotoNextSpine;
- (void)gotoPrevSpine;
- (void)gotoNextPage;
- (void)gotoPrevPage;
- (NSUInteger)getGlobalPageCount;
- (void)gotoPageInCurrentSpine:(NSUInteger)pageIndex;
- (void)updatePagination;
- (void)loadSpine:(NSUInteger)spineIndex atPageIndex:(NSUInteger)pageIndex;

@end

@implementation EPubViewController

#pragma mark -

- (void)loadEpub:(NSURL *)epubURL{
    currentSpineIndex = 0;
    currentPageInSpineIndex = 0;
    pagesInCurrentSpineCount = 0;
    totalPagesCount = 0;
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
    totalPagesCount += chapter.pageCount;

	if (chapter.chapterIndex + 1 < [self.loadedEpub.spineArray count]) {
        Chapter *currentChapter = self.loadedEpub.spineArray[chapter.chapterIndex + 1];
		[currentChapter setDelegate:self];
		[currentChapter loadChapterWithWindowSize:self.webView.bounds
                                  fontPercentSize:currentTextSize];
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

	[chaptersPopover dismissPopoverAnimated:YES];
	[searchResultsPopover dismissPopoverAnimated:YES];
	
	NSURL *url = [NSURL fileURLWithPath:[[self.loadedEpub.spineArray objectAtIndex:spineIndex] spinePath]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	
    currentPageInSpineIndex = pageIndex;
	currentSpineIndex = spineIndex;
	
    if (!self.paginating){
        [self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
	}
}


#pragma mark -
#pragma mark Navigation

- (void)gotoPageInCurrentSpine:(NSUInteger)pageIndex {
	if (pageIndex >= pagesInCurrentSpineCount){
		pageIndex = pagesInCurrentSpineCount - 1;
		currentPageInSpineIndex = pagesInCurrentSpineCount - 1;	
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
		if (currentSpineIndex + 1 < [self.loadedEpub.spineArray count]) {
			[self loadSpine:++currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoPrevSpine {
	if (!self.paginating){
		if ((int)(currentSpineIndex - 1) >= 0){
			[self loadSpine:--currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoNextPage {
	if (!self.paginating){
		if(currentPageInSpineIndex+1<pagesInCurrentSpineCount){
			[self gotoPageInCurrentSpine:++currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}		
	}
}

- (void)gotoPrevPage {
	if (!self.paginating) {
		if ((int)(currentSpineIndex - 1) >= 0){
			[self gotoPageInCurrentSpine:--currentPageInSpineIndex];
		} else {
			if (currentSpineIndex != 0){
                Chapter *currentChapter = self.loadedEpub.spineArray[currentSpineIndex - 1];
				NSUInteger targetPage = [currentChapter pageCount];
				[self loadSpine:--currentSpineIndex atPageIndex:targetPage - 1];
			}
		}
	}
}

#pragma mark -
#pragma mark Page Label

- (void)setPageLabelForAmountOnly {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"?/%ld", totalPagesCount]];
}

- (void)setPageLabelForAmountAndIndex {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", [self getGlobalPageCount], totalPagesCount]];
}

#pragma mark -
#pragma mark Pagination

- (NSUInteger)getGlobalPageCount{
    __block NSUInteger pageCount = 0;
    
    [self.loadedEpub.spineArray enumerateObjectsUsingBlock:^(Chapter *currentChapter, NSUInteger idx, BOOL *stop) {
        if (idx < currentSpineIndex) {
            pageCount += [currentChapter pageCount];
        }
        else {
            *stop = YES;
        }
    }];
    
    pageCount += currentPageInSpineIndex + 1;
    return pageCount;
}

- (void)updatePagination{
    if (self.epubLoaded){
        if (!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            totalPagesCount = 0;
            
            [self loadSpine:currentSpineIndex atPageIndex:currentPageInSpineIndex];
            
            Chapter *chapter = self.loadedEpub.spineArray[0];
            
            [chapter setDelegate:self];
            [chapter loadChapterWithWindowSize:self.webView.bounds
                               fontPercentSize:currentTextSize];
            [self.currentPageLabel setText:@"?/?"];
        }
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)increaseTextSizeClicked:(id)sender{
	if (!self.paginating){
		if (currentTextSize + kChangeTextStep <= kMaxTextSize){
			currentTextSize += kChangeTextStep;
			[self updatePagination];
			if (currentTextSize == kMaxTextSize){
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.paginating){
		if (currentTextSize - kChangeTextStep >= kMinTextSize) {
			currentTextSize -= kChangeTextStep;
			[self updatePagination];
			
            if (currentTextSize == kMinTextSize) {
				[self.decTextSizeButton setEnabled:NO];
			}
            
			[self.incTextSizeButton setEnabled:YES];
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


#pragma mark -
#pragma mark Slider

- (void)updateSliderValue {
    [self.pageSlider setValue:100.0 * (float)[self getGlobalPageCount] / (float)totalPagesCount
                     animated:YES];
}

- (NSUInteger)currentSliderPage {
    NSUInteger currentSliderPage = (NSUInteger)((self.pageSlider.value / 100.0) * (float)totalPagesCount);
    return currentSliderPage;
}

- (IBAction)slidingStarted:(id)sender {
    NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage++;
    }
    
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", targetPage, totalPagesCount]];
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
    
    [self gotoPageInCurrentSpine:currentPageInSpineIndex];
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
    
    currentTextSize = 100;
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
