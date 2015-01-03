//
//  AppDelegate.m
//  SK_EPReader
//
//  Created by skyylex on 1/3/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after app launch.
    
    self.window.rootViewController = self.detailViewController;
    [self.window makeKeyAndVisible];
    
    NSString *epubFilepath = [[NSBundle mainBundle] pathForResource:@"vhugo" ofType:@"epub"];
    
    [self.detailViewController loadEpub:[NSURL fileURLWithPath:epubFilepath]];
    
    return YES;
}

@end
