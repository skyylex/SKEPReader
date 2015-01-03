//
//  AePubReaderAppDelegate.m
//  AePubReader
//
//  Created by Federico Frappi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AePubReaderAppDelegate.h"


#import "EPubViewController.h"


@implementation AePubReaderAppDelegate


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch.
    
    self.window.rootViewController = self.detailViewController;
    [self.window makeKeyAndVisible];
    
    NSString *epubFilepath = [[NSBundle mainBundle] pathForResource:@"vhugo" ofType:@"epub"];
    
    [self.detailViewController loadEpub:[NSURL fileURLWithPath:epubFilepath]];
    
    return YES;
}

@end

