
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface UIWebView (SearchWebView)

- (NSInteger)highlightAllOccurencesOfString:(NSString *)str;
- (void)removeAllHighlights;

@end