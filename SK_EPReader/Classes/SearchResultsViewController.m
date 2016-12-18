//
//  SearchResultsViewController.m
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchResultsViewController.h"
#import "SearchResult.h"
#import "UIWebView+SearchWebView.h"

@interface SearchResultsViewController()

- (void) searchString:(NSString *)query inChapterAtIndex:(int)index;

@end


@implementation SearchResultsViewController

@synthesize resultsTableView, epubViewController, currentQuery, results;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    SearchResult *hit = (SearchResult*)results[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"...%@...", hit.neighboringText];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Chapter %d - page %d", hit.chapterIndex, hit.pageIndex+1];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return results.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    SearchResult *hit = (SearchResult*)results[indexPath.row];

    [epubViewController loadChapter:hit.chapterIndex atPageIndex:hit.pageIndex highlightSearchResult:hit];
}

- (void)searchString:(NSString *)query{
    self.results = [NSMutableArray array];
    [resultsTableView reloadData];
    self.currentQuery = query;
    [self searchString:query inChapterAtIndex:0];    
}

- (void)searchString:(NSString *)query inChapterAtIndex:(int)index{
    currentChapterIndex = index;
    
    Chapter *chapter = epubViewController.loadedEpub.chapters[index];
    
    NSRange range = NSMakeRange(0, chapter.text.length);
    range = [chapter.text rangeOfString:query options:NSCaseInsensitiveSearch range:range locale:nil];
    int hitCount = 0;
    while (range.location != NSNotFound) {
        int location = range.location + range.length;
        int length = chapter.text.length - (range.location + range.length);
        range = NSMakeRange(location, length);
        range = [chapter.text rangeOfString:query options:NSCaseInsensitiveSearch range:range locale:nil];
        hitCount++;
    }
    
    if (hitCount != 0) {
        NSURL *url = [NSURL fileURLWithPath:chapter.spinePath];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:chapter.windowSize];
        webView.delegate = self;
        
        [webView loadRequest:urlRequest];
    } else {
        if (currentChapterIndex + 1 < epubViewController.loadedEpub.chapters.count) {
            [self searchString:currentQuery inChapterAtIndex:(currentChapterIndex + 1)];
        } else {
            epubViewController.searching = NO;
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"%@", error);
}

- (void) webViewDidFinishLoad:(UIWebView*)webView{
    NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
    "mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
    "ruleIndex = mySheet.cssRules.length;"
    "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
    "}"
	"}";
	
//    NSLog(@"w:%f h:%f", webView.bounds.size.width, webView.bounds.size.height);
	
    Chapter *chapter = epubViewController.loadedEpub.chapters[currentChapterIndex];
    
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", chapter.fontPercentSize];
    
	
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
    [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    
    [webView highlightAllOccurencesOfString:currentQuery];
    
    NSString* foundHits = [webView stringByEvaluatingJavaScriptFromString:@"results"];
    
//    NSLog(@"%@", foundHits);
    
    NSMutableArray* objects = [NSMutableArray array];
    
    NSArray *strings = [foundHits componentsSeparatedByString:@";"];
    for (int i = 0; i < strings.count; i++) {
        NSArray *str = [strings[i] componentsSeparatedByString:@","];
        if (str.count == 3){
            [objects addObject:str];   
        }
    }
    
    NSArray *orderedResults = [objects sortedArrayUsingComparator:^(id first, id second){
                                            int x1 = [[first objectAtIndex:0] intValue];
                                            int x2 = [[second objectAtIndex:0] intValue];
                                            int y1 = [[first objectAtIndex:1] intValue];
                                            int y2 = [[second objectAtIndex:1] intValue];
                                            if(y1<y2){
                                                return NSOrderedAscending;
                                            } else if(y1>y2){
                                                return NSOrderedDescending;
                                            } else {
                                                if(x1<x2){
                                                    return NSOrderedAscending;
                                                } else if (x1>x2){
                                                    return NSOrderedDescending;
                                                } else {
                                                    return NSOrderedSame;
                                                }
                                            }
    }];
    
    
    for (int i = 0; i < orderedResults.count; i++) {
        NSArray *currObj = orderedResults[i];
        
        int pageIndex = ([currObj[1] intValue] / webView.bounds.size.height);
        NSString *javascriptCall = [NSString stringWithFormat:@"unescape('%@')", currObj[2]];
        NSString *text = [webView stringByEvaluatingJavaScriptFromString:javascriptCall];
        SearchResult *result = [[SearchResult alloc] initWithChapterIndex:currentChapterIndex
                                                                   pageIndex:pageIndex
                                                                 hitIndex:0
                                                             neighboringText:text
                                                            originatingQuery:currentQuery];
        [results addObject:result];
    }
    
    __weak SearchResultsViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.resultsTableView reloadData];
    });
    
    if (currentChapterIndex + 1 < epubViewController.loadedEpub.chapters.count){
        [self searchString:currentQuery inChapterAtIndex:(currentChapterIndex + 1)];
    } else {
        epubViewController.searching = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
