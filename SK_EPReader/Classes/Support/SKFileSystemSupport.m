//
//  SKFileSystemSupport.m
//  SK_EPReader
//
//  Created by skyylex on 12/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import "SKFileSystemSupport.h"
#import <KSCrypto/KSSHA1Stream.h>

@implementation SKFileSystemSupport

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString {
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:filePathString], @"no file and directory");
    
    NSError *error = nil;
    NSURL *URL= [NSURL fileURLWithPath:filePathString];
    BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey:NSURLIsExcludedFromBackupKey error:&error];
    
    if (success == NO){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    
    return success;
}

+ (void)createDirectoryIfNeeded:(NSString *)directoryPath {
    NSParameterAssert(directoryPath);
    
    BOOL isDirectory = NO;
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath
                                                             isDirectory:&isDirectory];
    if (directoryExists == NO) {
        [[self class] createDirectory:directoryPath];
    }
}

+ (void)createDirectory:(NSString *)directoryPath {
    NSParameterAssert(directoryPath);
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        NSLog(@"Create directory error: %@", error);
    }
}

+ (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString *)saveFileURLDataToTheTempFolder:(NSString *)sourceURLString {
    NSParameterAssert(sourceURLString != nil);
    
    NSURL *bookURL = [NSURL fileURLWithPath:sourceURLString];
    NSData *bookData = [NSData dataWithContentsOfURL:bookURL];
    NSString *resultTempPath = nil;
    if (bookData) {
        NSString *sha1String = [bookData ks_SHA1DigestString];
        NSString *epubFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:sha1String];
        BOOL savingResult = [bookData writeToFile:epubFilePath atomically:YES];
        if (savingResult == YES) {
            resultTempPath = epubFilePath;
        }
    }
    
    return resultTempPath;
}

@end
