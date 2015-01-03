//
//  AppDelegate.h
//  SK_EPReader
//
//  Created by skyylex on 1/3/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPubViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet EPubViewController *detailViewController;


@end

