//
//  SKFileSystemSupport.h
//  SK_EPReader
//
//  Created by skyylex on 12/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKFileSystemSupport : NSObject

// Backup configuration
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

// Shortcuts for system paths
+ (NSString *)applicationSupportDirectory;

// File system changes
+ (BOOL)removeFileSystemItem:(NSString *)item;
+ (void)createDirectoryIfNeeded:(NSString *)directoryPath;
+ (NSString *)saveFileToTemp:(NSString *)filepath;

// Archiving
+ (BOOL)unzipEpub:(NSString *)filename toDirectory:(NSString *)directory;

@end
