//
//  MHCameraRoll.m
//  pxlcld-ios
//
//  Created by Matej Hrescak on 3/19/14.
//  Copyright (c) 2014 facebook. All rights reserved.
//

#import "MHCameraRoll.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface MHCameraRoll()

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) NSMutableDictionary *thumbCache;

@end

@implementation MHCameraRoll

- (id)init
{
    self = [super init];
    if (self) {
        self.library = [[ALAssetsLibrary alloc] init];
        self.fileTypes = MHCameraRollFileTypesAll;
        self.thumbStyle = MHCameraRollThumbStyleSmallSquare;
        self.images = [[NSMutableArray alloc] init];
        self.thumbCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - loading

- (void)loadCameraRollWithSuccess:(void(^)(void))success
                     unauthorized:(void(^)(void))unauthorized
{
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied ||
        [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted) {
        unauthorized();
    } else {
        [self.library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
                if (alAsset) {
                    ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                    NSString *fileName = [representation filename];
                    if ([self shouldReadFileOfExtension:[fileName pathExtension]]) {
                        NSDictionary *image = @{@"fileName": fileName,
                                                @"URL": [representation url]};
                        [self.images addObject:image];
                    }
                }
            }];
            success();
            
        } failureBlock:^(NSError *error) {
            if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                NSLog(@"user denied access to camera roll, code: %li",(long)error.code);
                unauthorized();
            }else{
                NSLog(@"Other camera roll error code: %li",(long)error.code);
            }
        }];
    }
}

#pragma mark - custom style setter

- (void)setThumbStyle:(MHCameraRollThumbStyle)thumbStyle
{
    _thumbStyle = thumbStyle;
    //purge the thumb cache since the scale is not relevant anymore
    [self.thumbCache removeAllObjects];
}

#pragma mark - image access

- (NSInteger)imageCount
{
    return [self.images count];
}

- (NSString *)fileNameAtIndex:(NSInteger)index
{
    NSString *fileName = @"";
    NSDictionary *image = [self.images objectAtIndex:index];
    if (image) {
        fileName = [image objectForKey:@"fileName"];
    }
    
    return fileName;
}

- (void)thumbAtIndex:(NSInteger)index completionHandler:(void(^)(UIImage *thumb))completionHandler
{
    UIImage *thumb = self.thumbCache[[NSNumber numberWithInteger:index]];
    if (thumb) {
        //return cached thumbnail if we have one
        completionHandler(thumb);
    } else {
        //create new one and save to cache if we don't
        [self.library assetForURL:self.images[index][@"URL"] resultBlock:^(ALAsset *asset) {
            UIImage *thumb = [[UIImage alloc] init];
            if (self.thumbStyle == MHCameraRollThumbStyleSmallSquare) {
                thumb = [UIImage imageWithCGImage:[asset thumbnail]];
            } else {
                thumb = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
            }
            [self.thumbCache setObject:thumb forKey:[NSNumber numberWithInteger:index]];
            completionHandler(thumb);
        } failureBlock:^(NSError *error) {
            NSLog(@"Error loading asset");
        }];
    }
}

- (void)imageAtIndex:(NSInteger)index completionHandler:(void(^)(UIImage *image))completionHandler
{
    NSDictionary *image = self.images[index];
    [self.library assetForURL:image[@"URL"] resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        UIImage *returnImage = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                   scale:[representation scale]
                                             orientation:(int)[representation orientation]];
        completionHandler(returnImage);
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading asset");
    }];
}

- (void)CGImageAtIndex:(NSInteger)index completionHandler:(void(^)(CGImageRef CGImage))completionHandler
{
    NSDictionary *image = self.images[index];
    [self.library assetForURL:image[@"URL"] resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        completionHandler([representation fullResolutionImage]);
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading asset");
    }];
}

#pragma mark - helper methods

-(BOOL)shouldReadFileOfExtension:(NSString *)extension{
    if (self.fileTypes == MHCameraRollFileTypesAll) {
        //load all images
        return YES;
    } else if (self.fileTypes == MHCameraRollFileTypesPhotos){
        //load only photos
        return [extension isEqualToString:@"JPEG"] ||
                [extension isEqualToString:@"jpeg"] ||
                [extension isEqualToString:@"jpg"] ||
                [extension isEqualToString:@"JPG"];
    } else if (self.fileTypes == MHCameraRollFileTypesScreenshots){
        // load only screenshots
        return [extension isEqualToString:@"PNG"] ||
        [extension isEqualToString:@"png"];
    }
    return NO;
}


@end
