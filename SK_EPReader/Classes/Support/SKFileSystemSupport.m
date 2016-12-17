//
//  SKFileSystemSupport.m
//  SK_EPReader
//
//  Created by skyylex on 12/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import "SKFileSystemSupport.h"
#import <ZipArchive/ZipArchive.h>
#import <KSCrypto/KSSHA1Stream.h>

@implementation SKFileSystemSupport

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString {
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:filePathString], @"no file and directory");
    
    NSError *error = nil;
    NSURL *URL = [NSURL fileURLWithPath:filePathString];
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

+ (NSString *)saveFileToTemp:(NSString *)filepath {
    NSParameterAssert(filepath != nil);
    
    NSURL *bookURL = [NSURL fileURLWithPath:filepath];
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

+ (BOOL)removeFileSystemItem:(NSString *)item {
    NSFileManager *filemanager = [[NSFileManager alloc] init];
    if ([filemanager fileExistsAtPath:item]) {
        NSError *error = nil;
        [filemanager removeItemAtPath:item error:&error];
        
        return true;
    }
    
    return false;
}

+ (BOOL)unzipEpub:(NSString *)filename toDirectory:(NSString *)directory {
    ZipArchive *zipArchive = [ZipArchive new];
    if ([zipArchive UnzipOpenFile:filename]) {
        // Remove possible artefacts
        [SKFileSystemSupport removeFileSystemItem:directory];
        
        BOOL result = [zipArchive UnzipFileTo:[NSString stringWithFormat:@"%@/", directory]
                                    overWrite:YES];
        
        // According to default requirements in AppStore
        [SKFileSystemSupport addSkipBackupAttributeToItemAtPath:directory];
        
        [zipArchive UnzipCloseFile];
        
        return result;
    } else {
        return NO;
    }
}

@end
