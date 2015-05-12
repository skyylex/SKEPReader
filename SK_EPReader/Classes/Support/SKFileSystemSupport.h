//
//  SKFileSystemSupport.h
//  SK_EPReader
//
//  Created by skyylex on 12/05/15.
//  Copyright (c) 2015 skyylex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKFileSystemSupport : NSObject

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

+ (void)createDirectoryIfNeeded:(NSString *)directoryPath;
+ (NSString *)applicationSupportDirectory;
+ (NSString *)saveFileURLDataToTheTempFolder:(NSString *)sourceURLString;

@end
