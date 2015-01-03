//
//  SearchResult.m
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchResult.h"


@implementation SearchResult

- (instancetype)initWithChapterIndex:(int)theChapterIndex
                           pageIndex:(int)thePageIndex
                            hitIndex:(int)theHitIndex
                     neighboringText:(NSString *)theNeighboringText
                    originatingQuery:(NSString *)theOriginatingQuery {
    if (self = [super init]) {
        self.chapterIndex = theChapterIndex;
        self.pageIndex = thePageIndex;
        self.hitIndex = theHitIndex;
        self.neighboringText = [theNeighboringText stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.originatingQuery = theOriginatingQuery;
    }
    
    return self;
}


@end
