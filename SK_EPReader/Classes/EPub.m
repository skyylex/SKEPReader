//
//  EPub.m
//  AePubReader
//
//  Created by Federico Frappi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EPub.h"
#import "ZipArchive.h"
#import "Chapter.h"
#import "SKFileSystemSupport.h"
#import <KSCrypto/KSSHA1Stream.h>
#import "SKHashingSupport.h"

static NSString * const kMediaTypeKey = @"media-type";
static NSString * const kHrefTypeKey = @"href";
static NSString * const kOPFKey = @"opf";
static NSString * const kNCXKey = @"ncx";
static NSString * const kIDRefKey = @"idref";
static NSString * const kIDKey = @"id";
static NSString * const kIDPFKey = @"http://www.idpf.org/2007/opf";
static NSString * const kOPFItemKey = @"//opf:item";

@interface EPub()

@property (nonatomic, strong) NSString *unzippedBookDirectory;

@end

@implementation EPub

#pragma mark - Lifecycle

- (instancetype)initWithEPubPath:(NSString *)path {
	if (self = [super init]) {
        NSParameterAssert(path != nil);
        
		self.epubFilePath = path;
		self.chapters = [NSMutableArray array];
    
        self.sha1 = [SKHashingSupport generateSHA1:self.epubFilePath];
        NSString *applicationSupportDirectory = [SKFileSystemSupport applicationSupportDirectory];
        self.unzippedBookDirectory = [applicationSupportDirectory stringByAppendingPathComponent:self.sha1];

        // TODO: change the time of the call parseEpub.
        //       to be able to return result and proccess it 
        [self parseEpub];
	}
    
	return self;
}

#pragma mark - Parsing

- (void)parseEpub {
    BOOL result = [SKFileSystemSupport unzipEpub:self.epubFilePath
                                     toDirectory:self.unzippedBookDirectory];
    if (result == NO) {
        // TODO: add error handling
    }
    
	NSString *opfPath = [self retrieveOPFFilePathWith:self.unzippedBookDirectory];
	[self parseOPF:opfPath];
}

- (NSString *)buildManifestPathWith:(NSString *)unzippedPath {
    NSAssert(unzippedPath != nil, @"No unzipped path to generate manifest path");
    
    NSString *manifestFilePath = [NSString stringWithFormat:@"%@/META-INF/container.xml", unzippedPath];
    return manifestFilePath;
}

- (NSString *)retrieveOPFFilePathWith:(NSString *)unzippedPath {
    NSString *manifestPath = [self buildManifestPathWith:unzippedPath];
	NSFileManager *fileManager = [NSFileManager new];
	if ([fileManager fileExistsAtPath:manifestPath]) {
        NSURL *manifestURL = [NSURL fileURLWithPath:manifestPath];
        NSError *manifestReadingError = nil;
		CXMLDocument *manifestFile = [[CXMLDocument alloc] initWithContentsOfURL:manifestURL
                                                                         options:0
                                                                           error:&manifestReadingError];
		// TODO: handle manifestReadingError
        
        NSError *opfReadingError = nil;
        CXMLNode *opfPath = [manifestFile nodeForXPath:@"//@full-path[1]"
                                                 error:&opfReadingError];
        // TODO: handle opfReadingError
        
        NSString *opfRelativePath = opfPath.stringValue;
        return [unzippedPath stringByAppendingPathComponent:opfRelativePath];
	} else {
		NSLog(@"ERROR: ePub not Valid");
		return nil;
	}
}

- (void)parseOPF:(NSString *)opfPath{
    NSURL *opfFileURL = [NSURL fileURLWithPath:opfPath];
    NSError *opfReadingError = nil;
	CXMLDocument *opfFile = [[CXMLDocument alloc] initWithContentsOfURL:opfFileURL
                                                                options:0
                                                                  error:&opfReadingError];
	NSArray *itemsArray = [opfFile nodesForXPath:kOPFItemKey
                               namespaceMappings:@{kOPFKey : kIDPFKey}
                                           error:nil];
    
    NSString *ncxFileName;
	
    NSMutableDictionary* itemDictionary = [NSMutableDictionary dictionary];
	for (CXMLElement *element in itemsArray) {
        NSString *idValue = [element attributeForName:kIDKey].stringValue;
        NSString *hrefTypeValue = [element attributeForName:kHrefTypeKey].stringValue;
        NSString *mediaTypeValue = [element attributeForName:kMediaTypeKey].stringValue;
        
		[itemDictionary setValue:hrefTypeValue forKey:idValue];
        
        if ([mediaTypeValue isEqualToString:@"application/x-dtbncx+xml"]){
            ncxFileName = hrefTypeValue;
        } else if ([mediaTypeValue isEqualToString:@"application/xhtml+xml"]){
            ncxFileName = hrefTypeValue;
        }
	}
	
    NSUInteger lastSlash = [opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
	NSString *ebookBasePath = [opfPath substringToIndex:(lastSlash + 1)];
    NSURL *tocNCXURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName]];
    CXMLDocument *ncxToc = [[CXMLDocument alloc] initWithContentsOfURL:tocNCXURL
                                                               options:0
                                                                 error:nil];
    NSMutableDictionary *titleDictionary = [NSMutableDictionary dictionary];
    for (CXMLElement *element in itemsArray) {
        NSString *href = [element attributeForName:kHrefTypeKey].stringValue;
        NSString *xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
        
        NSDictionary *namespaceMappings = @{kNCXKey : @"http://www.daisy.org/z3986/2005/ncx/"};
        NSArray *navPoints = [ncxToc nodesForXPath:xpath
                                 namespaceMappings:namespaceMappings
                                             error:nil];
        if (navPoints.count != 0){
            CXMLElement *titleElement = navPoints[0];
            [titleDictionary setValue:titleElement.stringValue forKey:href];
        }
    }
    
    NSArray *itemRefsArray = [opfFile nodesForXPath:@"//opf:itemref"
                                  namespaceMappings:@{kOPFKey : kIDPFKey}
                                              error:nil];
	NSMutableArray *chapters = [NSMutableArray array];
    int count = 0;
	for (CXMLElement *element in itemRefsArray) {
        NSString *idRefValue = [element attributeForName:kIDRefKey].stringValue;
        NSString *chapHref = [itemDictionary valueForKey:idRefValue];
        
        NSString *chapterPath = [NSString stringWithFormat:@"%@%@", ebookBasePath, chapHref];
        NSString *title = [titleDictionary valueForKey:chapHref];
        Chapter *chapter = [[Chapter alloc] initWithPath:chapterPath
                                                      title:title
                                               chapterIndex:count++];
		[chapters addObject:chapter];
	}
	
	self.chapters = [NSArray arrayWithArray:chapters];
}

@end
