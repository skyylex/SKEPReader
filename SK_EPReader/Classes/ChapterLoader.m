//
//  ChapterLoader.m
//  SK_EPReader
//
//  Created by Yury Lapitsky on 17/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import "ChapterLoader.h"
#import <GTMNSStringHTMLAdditions/GTMNSString+HTML.h>
#import <MWFeedParser/NSString+HTML.h>

@interface ChapterLoader() <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong, readwrite) Chapter *chapter;

@end

@implementation ChapterLoader

- (instancetype)initWithChapter:(Chapter *)chapter {
    self = [super init];
    if (self) {
        self.chapter = chapter;
    }
    return self;
}

- (void)loadChapterWithWindowSize:(CGRect)theWindowSize
                  fontPercentSize:(NSUInteger)theFontPercentSize {
    self.chapter.fontPercentSize = theFontPercentSize;
    self.chapter.windowSize = theWindowSize;
    
    self.webView = [[UIWebView alloc] initWithFrame:self.chapter.windowSize];
    [self.webView setDelegate:self];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.chapter.spinePath]];
    [self.webView loadRequest:urlRequest];
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
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %ld%%;')", (unsigned long)self.chapter.fontPercentSize];
    
    
    [webView stringByEvaluatingJavaScriptFromString:varMySheet];
    [webView stringByEvaluatingJavaScriptFromString:addCSSRule];
    [webView stringByEvaluatingJavaScriptFromString:insertRule1];
    [webView stringByEvaluatingJavaScriptFromString:insertRule2];
    [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    
    float totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] floatValue];
    self.chapter.pageCount = (NSUInteger)(totalWidth / webView.bounds.size.width);
    
    self.webView = nil;
    
    [self.delegate chapterDidFinishLoad:self.chapter];
}

@end
