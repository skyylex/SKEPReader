//
//  SKBookListTableController.m
//  SK_EPReader
//
//  Created by skyylex on 11/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import "SKFileSystemSupport.h"
#import "SKBookListTableController.h"
#import "EpubViewController.h"

/// UITableView

static NSString *const SKBookCellIdentifier = @"SKBookCellIdentifier";

/// Books

static NSString *const SKSampleEpubBookTitleJLR = @"Japanese Layout Requirement W3C";
static NSString *const SKSampleEpubBookTitleMobyDick = @"Moby-Dick";

static NSString *const SKSampleEpubBookFileNameJLR = @"jlreq-in-english";
static NSString *const SKSampleEpubBookFileNameMobyDick = @"moby-dick";

static NSString *const SKEpubExtension = @"epub";

@interface SKBookListTableController ()

@property (nonatomic, strong) NSDictionary *bookInfoItems;
@property (nonatomic, strong) NSSortDescriptor *sortDescriptor;

@end

@implementation SKBookListTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    
    NSString *JLRPath = [[NSBundle mainBundle] pathForResource:SKSampleEpubBookFileNameJLR ofType:SKEpubExtension];
    NSString *mobyDickPath = [[NSBundle mainBundle] pathForResource:SKSampleEpubBookFileNameMobyDick ofType:SKEpubExtension];
    
    self.bookInfoItems = @{SKSampleEpubBookTitleJLR : JLRPath,
                           SKSampleEpubBookTitleMobyDick : mobyDickPath};
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    
    NSArray *sortedKeys = [self.bookInfoItems.allKeys sortedArrayUsingDescriptors:@[self.sortDescriptor]];
    NSString *urlString = [self.bookInfoItems objectForKey:sortedKeys[indexPath.row]];
    
    NSString *epubFilePath = [SKFileSystemSupport saveFileURLDataToTheTempFolder:urlString];
    NSURL *epubURL = [NSURL fileURLWithPath:epubFilePath];
    
    EPubViewController *epubViewController = [self.storyboard instantiateViewControllerWithIdentifier:EPubViewControllerStoryboardId];
    [epubViewController loadEpub:epubURL];
    [self presentViewController:epubViewController animated:YES completion:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bookInfoItems.allValues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SKBookCellIdentifier];
    NSArray *sortedKeys = [self.bookInfoItems.allKeys sortedArrayUsingDescriptors:@[self.sortDescriptor]];
    cell.textLabel.text = [self.bookInfoItems objectForKey:sortedKeys[indexPath.row]];
    cell.detailTextLabel.text = sortedKeys[indexPath.row];
    return cell;
}

@end
