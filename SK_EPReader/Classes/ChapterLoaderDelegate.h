//
//  ChapterLoaderDelegate.h
//  SK_EPReader
//
//  Created by Yury Lapitsky on 17/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chapter.h"

@class Chapter;

@protocol ChapterLoaderDelegate <NSObject>
- (void)chapterDidFinishLoad:(Chapter *)chapter;
@end
