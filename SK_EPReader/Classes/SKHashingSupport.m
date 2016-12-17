//
//  SKHashingSupport.m
//  SK_EPReader
//
//  Created by Yury Lapitsky on 17/12/2016.
//  Copyright © 2016 skyylex. All rights reserved.
//

#import "SKHashingSupport.h"
#import <KSCrypto/KSSHA1Stream.h>

@implementation SKHashingSupport

+ (NSString *)generateSHA1:(NSString *)filepath {
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filepath];
    NSAssert(fileExist, @"No file to calculate SHA1");
    
    NSData *epubData = [NSData dataWithContentsOfFile:filepath];
    NSString *sha1 = [epubData ks_SHA1DigestString];
    return sha1;
}

@end
