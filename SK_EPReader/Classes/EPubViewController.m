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

@interface EPubViewController(Outlets)

@end

@interface EPubViewController() <EpubRenderer>

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *chapterListButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *decTextSizeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *incTextSizeButton;
@property (nonatomic, strong) IBOutlet UISlider *pageSlider;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;

@property (nonatomic, strong) WYPopoverController *chaptersPopover;
@property (nonatomic, strong) WYPopoverController *searchResultsPopover;
@property (nonatomic, strong) SearchResultsViewController* searchResViewController;

@property (nonatomic, strong) ReaderPresenter *presenter;

@end

@implementation EPubViewController

#pragma mark - EpubReader

- (id<ChapterDelegate>)chapterDelegate {
    return self;
}

- (void)updateCurrentPageLabel:(NSString *)text {
    self.currentPageLabel.text = text;
}

- (CGRect)webviewFrame {
    return self.webView.bounds;
}

#pragma mark - Getters

- (EPub *)loadedEpub {
    return self.presenter.loadedEpub;
}

#pragma mark -

- (void)loadEpub:(NSURL *)epubURL{
    self.presenter.currentSpineIndex = 0;
    self.presenter.currentPageInSpineIndex = 0;
    self.presenter.pagesInCurrentSpineCount = 0;
    self.presenter.totalPagesCount = 0;
	self.searching = NO;
    
    self.presenter.epubLoaded = NO;
    self.presenter.loadedEpub = [[EPub alloc] initWithEPubPath:[epubURL path]];
    self.presenter.epubLoaded = YES;
    
    NSLog(@"loadEpub");
	[self.presenter updatePagination];
}

#pragma mark -
#pragma mark ChapterDelegate

- (void)chapterDidFinishLoad:(Chapter *)chapter{
    self.presenter.totalPagesCount += chapter.pageCount;

	if (chapter.chapterIndex + 1 < [self.loadedEpub.spineArray count]) {
        Chapter *currentChapter = self.loadedEpub.spineArray[chapter.chapterIndex + 1];
        [currentChapter load:self.webView.bounds fontPercentSize:self.presenter.currentTextSize delegate:self];
		[self setPageLabelForAmountOnly];
	} else {
		[self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
		self.presenter.paginating = NO;
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
	
    self.presenter.currentPageInSpineIndex = pageIndex;
	self.presenter.currentSpineIndex = spineIndex;
	
    if (!self.presenter.paginating){
        [self setPageLabelForAmountAndIndex];
        [self updateSliderValue];
	}
}


#pragma mark -
#pragma mark Navigation

- (void)gotoPageInCurrentSpine:(NSUInteger)pageIndex {
	if (pageIndex >= self.presenter.pagesInCurrentSpineCount){
		pageIndex = self.presenter.pagesInCurrentSpineCount - 1;
		self.presenter.currentPageInSpineIndex = self.presenter.pagesInCurrentSpineCount - 1;
	}
	
	float pageOffset = pageIndex * self.webView.bounds.size.width;

	NSString *goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString *goTo = [NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[self.webView stringByEvaluatingJavaScriptFromString:goTo];
	
	if (!self.presenter.paginating) {
		[self updateSliderValue];
	}
	
	self.webView.hidden = NO;
}

- (void)gotoNextSpine {
	if (!self.presenter.paginating) {
		if (self.presenter.currentSpineIndex + 1 < [self.loadedEpub.spineArray count]) {
			[self loadSpine:++self.presenter.currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoPrevSpine {
	if (!self.presenter.paginating){
		if ((int)(self.presenter.currentSpineIndex - 1) >= 0){
			[self loadSpine:--self.presenter.currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void)gotoNextPage {
	if (!self.presenter.paginating){
		if(self.presenter.currentPageInSpineIndex + 1 < self.presenter.pagesInCurrentSpineCount){
			[self gotoPageInCurrentSpine:++self.presenter.currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}		
	}
}

- (void)gotoPrevPage {
	if (!self.presenter.paginating) {
		if ((int)(self.presenter.currentSpineIndex - 1) >= 0){
			[self gotoPageInCurrentSpine:--self.presenter.currentPageInSpineIndex];
		} else {
			if (self.presenter.currentSpineIndex != 0){
                Chapter *currentChapter = self.loadedEpub.spineArray[self.presenter.currentSpineIndex - 1];
				NSUInteger targetPage = [currentChapter pageCount];
				[self loadSpine:--self.presenter.currentSpineIndex atPageIndex:targetPage - 1];
			}
		}
	}
}

#pragma mark -
#pragma mark Page Label

- (void)setPageLabelForAmountOnly {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"?/%ld", self.presenter.totalPagesCount]];
}

- (void)setPageLabelForAmountAndIndex {
    [self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", [self.presenter globalPageCount], self.presenter.totalPagesCount]];
}

#pragma mark -
#pragma mark Pagination



#pragma mark -
#pragma mark IBAction

- (IBAction)increaseTextSizeClicked:(id)sender{
	if (!self.presenter.paginating){
		if (self.presenter.currentTextSize + kChangeTextStep <= kMaxTextSize){
			self.presenter.currentTextSize += kChangeTextStep;
			[self.presenter updatePagination];
			if (self.presenter.currentTextSize == kMaxTextSize){
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.presenter.paginating){
		if (self.presenter.currentTextSize - kChangeTextStep >= kMinTextSize) {
			self.presenter.currentTextSize -= kChangeTextStep;
			[self.presenter updatePagination];
			
            if (self.presenter.currentTextSize == kMinTextSize) {
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
    float sliderPosition = [self.presenter calculateSliderPosition];
    [self.pageSlider setValue:sliderPosition animated:YES];
}

- (NSUInteger)currentSliderPage {
    NSUInteger currentSliderPage = (NSUInteger)((self.pageSlider.value / 100.0) * (float)self.presenter.totalPagesCount);
    return currentSliderPage;
}

- (IBAction)slidingStarted:(id)sender {
    NSUInteger targetPage = [self currentSliderPage];
    if (targetPage == 0) {
        targetPage++;
    }
    
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%ld/%ld", targetPage, self.presenter.totalPagesCount]];
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
        pageSum += currentChapter.pageCount;
        if (pageSum >= targetPage) {
            pageIndex = currentChapter.pageCount - 1 - pageSum + targetPage;
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
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.presenter.currentTextSize];
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
    self.presenter.pagesInCurrentSpineCount = (NSUInteger)(totalWidth / self.webView.bounds.size.width);
    
    [self gotoPageInCurrentSpine:self.presenter.currentPageInSpineIndex];
}

#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSLog(@"shouldAutorotate");
    [self.presenter updatePagination];
	return YES;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark View lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.presenter = [ReaderPresenter new];
    self.presenter.renderer = self;
    
}

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
    
    self.presenter.currentTextSize = 100;
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
