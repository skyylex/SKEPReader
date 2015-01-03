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

@interface EPubViewController()


- (void) gotoNextSpine;
- (void) gotoPrevSpine;
- (void) gotoNextPage;
- (void) gotoPrevPage;
- (int) getGlobalPageCount;
- (void) gotoPageInCurrentSpine: (int)pageIndex;
- (void) updatePagination;
- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex;


@end

@implementation EPubViewController

#pragma mark -

- (void) loadEpub:(NSURL *)epubURL{
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

- (void) chapterDidFinishLoad:(Chapter *)chapter{
    totalPagesCount += chapter.pageCount;

	if (chapter.chapterIndex + 1 < [self.loadedEpub.spineArray count]){
		[[self.loadedEpub.spineArray objectAtIndex:chapter.chapterIndex + 1] setDelegate:self];
		[[self.loadedEpub.spineArray objectAtIndex:chapter.chapterIndex + 1] loadChapterWithWindowSize:self.webView.bounds fontPercentSize:currentTextSize];
		[self.currentPageLabel setText:[NSString stringWithFormat:@"?/%d", totalPagesCount]];
	} else {
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], totalPagesCount]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)totalPagesCount animated:YES];
		self.paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

- (int)getGlobalPageCount{
	int pageCount = 0;
	for (int i = 0; i < currentSpineIndex; i++){
		pageCount+= [[self.loadedEpub.spineArray objectAtIndex:i] pageCount];
	}
    
	pageCount += currentPageInSpineIndex+1;
	return pageCount;
}

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult*)theResult{
	self.webView.hidden = YES;
	self.currentSearchResult = theResult;

	[chaptersPopover dismissPopoverAnimated:YES];
	[searchResultsPopover dismissPopoverAnimated:YES];
	
	NSURL *url = [NSURL fileURLWithPath:[[self.loadedEpub.spineArray objectAtIndex:spineIndex] spinePath]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	
    currentPageInSpineIndex = pageIndex;
	currentSpineIndex = spineIndex;
	
    if (!self.paginating){
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], totalPagesCount]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)totalPagesCount animated:YES];
	}
}

- (void) gotoPageInCurrentSpine:(int)pageIndex{
	if (pageIndex>=pagesInCurrentSpineCount){
		pageIndex = pagesInCurrentSpineCount - 1;
		currentPageInSpineIndex = pagesInCurrentSpineCount - 1;	
	}
	
	float pageOffset = pageIndex * self.webView.bounds.size.width;

	NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString* goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[self.webView stringByEvaluatingJavaScriptFromString:goTo];
	
	if (!self.paginating){
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], totalPagesCount]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)totalPagesCount animated:YES];
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
		if(currentSpineIndex - 1 >= 0){
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

- (void) gotoPrevPage {
	if (!self.paginating) {
		if (currentPageInSpineIndex - 1 >= 0){
			[self gotoPageInCurrentSpine:--currentPageInSpineIndex];
		} else {
			if (currentSpineIndex != 0){
				int targetPage = [[self.loadedEpub.spineArray objectAtIndex:(currentSpineIndex-1)] pageCount];
				[self loadSpine:--currentSpineIndex atPageIndex:targetPage - 1];
			}
		}
	}
}


- (IBAction)increaseTextSizeClicked:(id)sender{
	if (!self.paginating){
		if (currentTextSize +25 <= 200){
			currentTextSize += 25;
			[self updatePagination];
			if (currentTextSize == 200){
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.paginating){
		if (currentTextSize - 25 >= 50) {
			currentTextSize -= 25;
			[self updatePagination];
			
            if (currentTextSize == 50) {
				[self.decTextSizeButton setEnabled:NO];
			}
            
			[self.incTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction)doneClicked:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction) slidingStarted:(id)sender{
    int targetPage = ((self.pageSlider.value / (float)100) * (float)totalPagesCount);
    if (targetPage == 0) {
        targetPage++;
    }
    
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d", targetPage, totalPagesCount]];
}

- (IBAction) slidingEnded:(id)sender{
	int targetPage = (int)((self.pageSlider.value/(float)100)*(float)totalPagesCount);
    if (targetPage==0) {
        targetPage++;
    }
	int pageSum = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
	for (chapterIndex = 0; chapterIndex < [self.loadedEpub.spineArray count]; chapterIndex++){
		pageSum += [[self.loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount];
		if (pageSum >= targetPage) {
			pageIndex = [[self.loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
			break;
		}
	}
    
	[self loadSpine:chapterIndex atPageIndex:pageIndex];
}

- (IBAction)showChapterIndex:(id)sender{
	if(chaptersPopover==nil){
		ChapterListViewController* chapterListView = [[ChapterListViewController alloc] initWithNibName:@"ChapterListViewController" bundle:[NSBundle mainBundle]];
		[chapterListView setEpubViewController:self];
		chaptersPopover = [[UIPopoverController alloc] initWithContentViewController:chapterListView];
		[chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if ([chaptersPopover isPopoverVisible]) {
		[chaptersPopover dismissPopoverAnimated:YES];
	}
    else {
		[chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton
                                permittedArrowDirections:UIPopoverArrowDirectionAny
                                                animated:YES];
	}
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
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", currentTextSize];
	NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];

	
	[self.webView stringByEvaluatingJavaScriptFromString:varMySheet];
	
	[self.webView stringByEvaluatingJavaScriptFromString:addCSSRule];
		
	[self.webView stringByEvaluatingJavaScriptFromString:insertRule1];
	
	[self.webView stringByEvaluatingJavaScriptFromString:insertRule2];
	
	[self.webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	
	[self.webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
	
	if (self.currentSearchResult) {
	//	NSLog(@"Highlighting %@", currentSearchResult.originatingQuery);
        [self.webView highlightAllOccurencesOfString:self.currentSearchResult.originatingQuery];
	}
	
	
	int totalWidth = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	pagesInCurrentSpineCount = (int)((float)totalWidth/self.webView.bounds.size.width);
	
	[self gotoPageInCurrentSpine:currentPageInSpineIndex];
}

- (void) updatePagination{
	if (self.epubLoaded){
        if (!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            totalPagesCount=0;
            [self loadSpine:currentSpineIndex atPageIndex:currentPageInSpineIndex];
            [self.loadedEpub.spineArray[0] setDelegate:self];
            [self.loadedEpub.spineArray[0] loadChapterWithWindowSize:self.webView.bounds fontPercentSize:currentTextSize];
            [self.currentPageLabel setText:@"?/?"];
        }
	}
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	if (!searchResultsPopover) {
		searchResultsPopover = [[UIPopoverController alloc] initWithContentViewController:searchResViewController];
		[searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if (![searchResultsPopover isPopoverVisible]) {
		[searchResultsPopover presentPopoverFromRect:searchBar.bounds inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
//	NSLog(@"Searching for %@", [searchBar text]);
    
	if (!self.searching){
		self.searching = YES;
		[searchResViewController searchString:[searchBar text]];
        [searchBar resignFirstResponder];
	}
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
#pragma mark View lifecycle

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.webView setDelegate:self];
		
	UIScrollView *sv = nil;
	for (UIView* v in self.webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
    
	currentTextSize = 100;	 
	
	UISwipeGestureRecognizer* rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoNextPage)];
	[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	UISwipeGestureRecognizer* leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPrevPage)];
	[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	
	[self.webView addGestureRecognizer:rightSwipeRecognizer];
	[self.webView addGestureRecognizer:leftSwipeRecognizer];
	
	[self.pageSlider setThumbImage:[UIImage imageNamed:@"slider_ball.png"]
                     forState:UIControlStateNormal];
	[self.pageSlider setMinimumTrackImage:[[UIImage imageNamed:@"orangeSlide.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0]
                            forState:UIControlStateNormal];
	[self.pageSlider setMaximumTrackImage:[[UIImage imageNamed:@"yellowSlide.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0]
                            forState:UIControlStateNormal];
    
	searchResViewController = [[SearchResultsViewController alloc] initWithNibName:@"SearchResultsViewController" bundle:[NSBundle mainBundle]];
	searchResViewController.epubViewController = self;
}


@end
