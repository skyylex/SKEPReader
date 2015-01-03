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

static NSString * const kMediaTypeKey = @"media-type";
static NSString * const kHrefTypeKey = @"href";
static NSString * const kOPFKey = @"opf";
static NSString * const kNCXKey = @"ncx";
static NSString * const kIDRefKey = @"idref";
static NSString * const kIDKey = @"id";
static NSString * const kIDPFKey = @"http://www.idpf.org/2007/opf";
static NSString * const kOPFItemKey = @"//opf:item";

@interface EPub()

- (void)parseEpub;
- (void)unzipAndSaveFileNamed:(NSString*)fileName;
- (NSString *)applicationDocumentsDirectory;
- (NSString *)parseManifestFile;
- (void)parseOPF:(NSString *)opfPath;

@end

@implementation EPub

- (instancetype)initWithEPubPath:(NSString *)path {
	if (self = [super init]){
		self.epubFilePath = path;
		self.spineArray = [NSMutableArray array];
		[self parseEpub];
	}
    
	return self;
}

- (void)parseEpub {
	[self unzipAndSaveFileNamed:self.epubFilePath];
    
	NSString *opfPath = [self parseManifestFile];
	[self parseOPF:opfPath];
}

- (void)unzipAndSaveFileNamed:(NSString *)fileName{
	ZipArchive *zipArchive = [[ZipArchive alloc] init];
	if ([zipArchive UnzipOpenFile:self.epubFilePath]) {
		NSString *strPath = [NSString stringWithFormat:@"%@/UnzippedEpub",[self applicationDocumentsDirectory]];
        
		//Delete all the previous files
		NSFileManager *filemanager = [[NSFileManager alloc] init];
		if ([filemanager fileExistsAtPath:strPath]) {
			NSError *error;
			[filemanager removeItemAtPath:strPath error:&error];
		}
		
        //start unzip
		BOOL ret = [zipArchive UnzipFileTo:[NSString stringWithFormat:@"%@/",strPath]
                                 overWrite:YES];
		if (NO == ret) {
			// error handler here
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Error while unzipping the epub"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
			[alert show];
		}
        
		[zipArchive UnzipCloseFile];
	}
}

- (NSString *)applicationDocumentsDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)parseManifestFile{
	NSString *manifestFilePath = [NSString stringWithFormat:@"%@/UnzippedEpub/META-INF/container.xml", [self applicationDocumentsDirectory]];
	NSFileManager *fileManager = [NSFileManager new];
	if ([fileManager fileExistsAtPath:manifestFilePath]) {
		//		NSLog(@"Valid epub");
		CXMLDocument *manifestFile = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:manifestFilePath]
                                                                         options:0
                                                                           error:nil];
		CXMLNode *opfPath = [manifestFile nodeForXPath:@"//@full-path[1]"
                                                 error:nil];

		return [NSString stringWithFormat:@"%@/UnzippedEpub/%@", [self applicationDocumentsDirectory], [opfPath stringValue]];
	} else {
		NSLog(@"ERROR: ePub not Valid");
		return nil;
	}
}

- (void)parseOPF:(NSString *)opfPath{
	CXMLDocument *opfFile = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:opfPath]
                                                                options:0
                                                                  error:nil];
	NSArray* itemsArray = [opfFile nodesForXPath:kOPFItemKey
                               namespaceMappings:[NSDictionary dictionaryWithObject:kIDPFKey
                                                                             forKey:kOPFKey]
                                           error:nil];
    //	NSLog(@"itemsArray size: %d", [itemsArray count]);
    
    NSString *ncxFileName;
	
    NSMutableDictionary* itemDictionary = [NSMutableDictionary dictionary];
	for (CXMLElement *element in itemsArray) {
		[itemDictionary setValue:[[element attributeForName:kHrefTypeKey] stringValue]
                          forKey:[[element attributeForName:kIDKey] stringValue]];
        if ([[[element attributeForName:kMediaTypeKey] stringValue] isEqualToString:@"application/x-dtbncx+xml"]){
            ncxFileName = [[element attributeForName:kHrefTypeKey] stringValue];
            //          NSLog(@"%@ : %@", [[element attributeForName:@"id"] stringValue], [[element attributeForName:@"href"] stringValue]);
        }
        
        if ([[[element attributeForName:kMediaTypeKey] stringValue] isEqualToString:@"application/xhtml+xml"]){
            ncxFileName = [[element attributeForName:kHrefTypeKey] stringValue];
            //          NSLog(@"%@ : %@", [[element attributeForName:@"id"] stringValue], [[element attributeForName:@"href"] stringValue]);
        }
	}
	
    int lastSlash = [opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
	NSString *ebookBasePath = [opfPath substringToIndex:(lastSlash +1)];
    NSURL *tocNCXURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName]];
    CXMLDocument *ncxToc = [[CXMLDocument alloc] initWithContentsOfURL:tocNCXURL
                                                               options:0
                                                                 error:nil];
    NSMutableDictionary *titleDictionary = [NSMutableDictionary dictionary];
    for (CXMLElement *element in itemsArray) {
        NSString *href = [[element attributeForName:kHrefTypeKey] stringValue];
        NSString *xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
        
        NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/"
                                                                      forKey:kNCXKey];
        NSArray *navPoints = [ncxToc nodesForXPath:xpath
                                 namespaceMappings:namespaceMappings
                                             error:nil];
        if (navPoints.count != 0){
            CXMLElement *titleElement = navPoints[0];
            [titleDictionary setValue:[titleElement stringValue] forKey:href];
        }
    }
    
    NSDictionary *namespaceDict = [NSDictionary dictionaryWithObject:kIDPFKey
                                                              forKey:kOPFKey];
	NSArray *itemRefsArray = [opfFile nodesForXPath:@"//opf:itemref"
                                  namespaceMappings:namespaceDict
                                              error:nil];
	NSMutableArray *tmpArray = [NSMutableArray array];
    int count = 0;
	for (CXMLElement *element in itemRefsArray) {
        NSString *chapHref = [itemDictionary valueForKey:[[element attributeForName:kIDRefKey] stringValue]];
        
        Chapter *tmpChapter = [[Chapter alloc] initWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, chapHref]
                                                      title:[titleDictionary valueForKey:chapHref]
                                               chapterIndex:count++];
		[tmpArray addObject:tmpChapter];
	}
	
	self.spineArray = [NSArray arrayWithArray:tmpArray];
}


@end
