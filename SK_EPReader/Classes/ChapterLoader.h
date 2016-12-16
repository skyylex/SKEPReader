//
//  ChapterLoader.h
//  SK_EPReader
//
//  Created by Yury Lapitsky on 17/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chapter.h"

@interface ChapterLoader : NSObject

@property (nonatomic, strong) id<ChapterLoaderDelegate> delegate;
@property (nonatomic, strong, readonly) Chapter *chapter;

- (instancetype)initWithChapter:(Chapter *)chapter;

- (void)loadChapterWithWindowSize:(CGRect)theWindowSize
                  fontPercentSize:(NSUInteger)theFontPercentSize;

@end
