//
//  ReadingState.h
//  SK_EPReader
//
//  Created by Yury Lapitsky on 31/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadingState : NSObject

+ (instancetype)blankState;

// Last viewed position
@property (nonatomic, assign) int chapterIndex;
@property (nonatomic, assign) int pageInChapter;

// Processing information
@property (nonatomic, assign) int total;
@property (nonatomic, assign, readonly) int textSize;

- (BOOL)canIncreaseFontSize;
- (BOOL)canDecreaseFontSize;

- (void)increaseFontOnStep;
- (void)decreaseFontOnStep;

@end
