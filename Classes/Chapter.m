//
//  Chapter.m
//  AePubReader
//
//  Created by Federico Frappi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Chapter.h"
#import "NSString+HTML.h"

@interface Chapter() {
    UIWebView *webView;
}

@end

@implementation Chapter 

- (id) initWithPath:(NSString*)theSpinePath title:(NSString*)theTitle chapterIndex:(int) theIndex{
    if((self=[super init])){
        self.spinePath = theSpinePath;
        self.title = theTitle;
        self.chapterIndex = theIndex;

		NSString *html = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:theSpinePath]] encoding:NSUTF8StringEncoding];
		self.text = [html stringByConvertingHTMLToPlainText];
    }
    return self;
}

- (void) loadChapterWithWindowSize:(CGRect)theWindowSize fontPercentSize:(int) theFontPercentSize{
    self.fontPercentSize = theFontPercentSize;
    self.windowSize = theWindowSize;
//  NSLog(@"webviewSize: %f * %f, fontPercentSize: %d", theWindowSize.size.width, theWindowSize.size.height,theFontPercentSize);
    webView = [[UIWebView alloc] initWithFrame:self.windowSize];
    [webView setDelegate:self];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.spinePath]];
    [webView loadRequest:urlRequest];
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
	
//	NSLog(@"w:%f h:%f", webView.bounds.size.width, webView.bounds.size.height);
	
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.fontPercentSize];
    
	
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
		
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
	
    [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    
	int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	self.pageCount = (int)((float)totalWidth/webView.bounds.size.width);
	
//    NSLog(@"Chapter %d: %@ -> %d pages", chapterIndex, title, pageCount);
    
    [self.delegate chapterDidFinishLoad:self];
    
}



@end
