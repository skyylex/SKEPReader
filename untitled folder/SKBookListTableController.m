//
//  SKBookListTableController.m
//  SK_EPReader
//
//  Created by skyylex on 11/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

#import "SKBookListTableController.h"
#import "EpubViewController.h"
#import <KSSHA1Stream.h>

/// UITableView

static NSString *const SKBookCellIdentifier = @"SKBookCellIdentifier";

/// Books

static NSString *const SKAuthorVHugo = @"Victor Hugo";
static NSString *const SKSampleEpubBookURLNotreDam = @"https://ebooks.adelaide.edu.au/h/hugo/victor/notredame/notredame.epub";

@interface SKBookListTableController ()

@property (nonatomic, strong) NSDictionary *bookInfoItems;
@property (nonatomic, strong) NSSortDescriptor *sortDescriptor;

@end

@implementation SKBookListTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    self.bookInfoItems = @{SKAuthorVHugo : SKSampleEpubBookURLNotreDam};
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    NSArray *sortedKeys = [self.bookInfoItems.allKeys sortedArrayUsingDescriptors:@[self.sortDescriptor]];
    NSString *urlString = [self.bookInfoItems objectForKey:sortedKeys[indexPath.row]];
    NSURL *bookURL = [NSURL URLWithString:urlString];
    NSData *bookData = [NSData dataWithContentsOfURL:bookURL];
    
    NSString *epubFilePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), [bookData ks_SHA1DigestString]];
    NSURL *epubURL = [NSURL URLWithString:epubFilePath];
    [bookData writeToFile:epubFilePath atomically:YES];
    EPubViewController *epubViewController = [EPubViewController new];
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
