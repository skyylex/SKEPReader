//
//  Chapter.h
//  AePubReader
//
//  Created by Federico Frappi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ChapterLoaderDelegate.h"

@class ChapterLoader;

@interface Chapter : NSObject <UIWebViewDelegate>

@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, assign) NSUInteger chapterIndex;
@property (nonatomic, assign) NSUInteger fontPercentSize;

@property (nonatomic, strong) NSString *spinePath;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;

@property (nonatomic, assign) CGRect windowSize;

- (id)initWithPath:(NSString *)theSpinePath
             title:(NSString *)theTitle
      chapterIndex:(NSUInteger)theIndex;

@end
