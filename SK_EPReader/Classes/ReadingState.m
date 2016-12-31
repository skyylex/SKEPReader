//
//  ReadingState.m
//  SK_EPReader
//
//  Created by Yury Lapitsky on 31/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import "ReadingState.h"

#define kMinTextSize 50
#define kMaxTextSize 200
#define kChangeTextStep 25

#define kDefaultTextSize 100

@interface ReadingState()

@property (nonatomic, assign, readwrite) int textSize;

@end

@implementation ReadingState

+ (instancetype)blankState {
    ReadingState *blank = [ReadingState new];
    
    blank.total = 0;
    blank.chapterIndex = 0;
    blank.pageInChapter = 0;
    
    blank.textSize = kDefaultTextSize;
    
    return blank;
}

#pragma mark - Font size

- (BOOL)canIncreaseFontSize {
    return (self.textSize + kChangeTextStep <= kMaxTextSize);
}

- (BOOL)canDecreaseFontSize {
    return (self.textSize - kChangeTextStep >= kMinTextSize);
}

- (void)increaseFontOnStep {
    self.textSize += kChangeTextStep;
}

- (void)decreaseFontOnStep {
    self.textSize -= kChangeTextStep;
}

@end
