//
//  MHCameraRoll.m
//  pxlcld-ios
//
//  Created by Matej Hrescak on 3/19/14.
//  Copyright (c) 2014 facebook. All rights reserved.
//

#import "MHCameraRoll.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>


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

- (NSDictionary *)imageInfoAtIndex:(NSInteger)index{
    
    
    NSDictionary *image = [self.images objectAtIndex:index];
    return image;
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
        
        
        
        NSDictionary *imageInfo = [self.images objectAtIndex:index];
        UIImage *returnImage = nil;
        
        
        //this is Gif
        if([imageInfo[@"fileName"] containsString:@"GIF"]){
            
            
            Byte *buffer = (Byte*)malloc((NSUInteger)representation.size);
            NSUInteger buffered = [representation getBytes:buffer fromOffset:0.0 length:(NSUInteger)representation.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            returnImage = [UIImage sd_animatedGIFWithData:data];
            completionHandler(returnImage);
            
            
        }
        //PNG / JEPG
        else {
            
            
            returnImage = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                              scale:[representation scale]
                                        orientation:(int)[representation orientation]];
            
            completionHandler(returnImage);
            
        }
        
        
        
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














@implementation UIImage (GIF)

+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        
        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self sd_frameDurationAtIndex:i source:source];
            
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    
    return animatedImage;
}

+ (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (UIImage *)sd_animatedGIFNamed:(NSString *)name {
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 1.0f) {
        NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:retinaPath];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        return [UIImage imageNamed:name];
    }
    else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        return [UIImage imageNamed:name];
    }
}

- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return self;
    }
    
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    NSMutableArray *scaledImages = [NSMutableArray array];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (UIImage *image in self.images) {
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [scaledImages addObject:newImage];
    }
    
    UIGraphicsEndImageContext();
    
    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

@end
