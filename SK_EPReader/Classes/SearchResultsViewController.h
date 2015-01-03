//
//  SearchResultsViewController.h
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPubViewController.h"

@interface SearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate> {
    UITableView* resultsTableView;
    NSMutableArray* results;
    EPubViewController* __unsafe_unretained epubViewController;
    
    int currentChapterIndex;
    NSString* currentQuery;
}

@property (nonatomic, strong) IBOutlet UITableView* resultsTableView;
@property (nonatomic, unsafe_unretained) EPubViewController* epubViewController;
@property (nonatomic, strong) NSMutableArray* results;
@property (nonatomic, strong) NSString* currentQuery;

- (void) searchString:(NSString*)query;

@end
