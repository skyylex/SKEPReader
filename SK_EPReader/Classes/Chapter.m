//
//  Chapter.m
//  AePubReader
//
//  Created by Federico Frappi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Chapter.h"
#import <GTMNSStringHTMLAdditions/GTMNSString+HTML.h>
#import <MWFeedParser/NSString+HTML.h>

@implementation Chapter 

- (id)initWithPath:(NSString *)theSpinePath
             title:(NSString *)theTitle
      chapterIndex:(NSUInteger)theIndex {
    if (self = [super init]) {
        self.spinePath = theSpinePath;
        self.title = theTitle;
        self.chapterIndex = theIndex;

        NSData *spineData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:theSpinePath]];
		NSString *html = [[NSString alloc] initWithData:spineData
                                               encoding:NSUTF8StringEncoding];
		self.text = [html stringByConvertingHTMLToPlainText];
    }
    
    return self;
}

@end
