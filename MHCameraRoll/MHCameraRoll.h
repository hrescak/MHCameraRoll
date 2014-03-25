//
//  MHCameraRoll.h
//  pxlcld-ios
//
//  Created by Matej Hrescak on 3/19/14.
//  Copyright (c) 2014 facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHCameraRoll : NSObject

typedef NS_ENUM(NSInteger, MHCameraRollFileTypes) {
    MHCameraRollFileTypesAll,
    MHCameraRollFileTypesScreenshots,
    MHCameraRollFileTypesPhotos
};

typedef NS_ENUM(NSInteger, MHCameraRollThumbStyle) {
    MHCameraRollThumbStyleSmallSquare,
    MHCameraRollThumbStyleOriginalRatio
};

@property (nonatomic, assign) MHCameraRollFileTypes fileTypes;
@property (nonatomic, assign) MHCameraRollThumbStyle thumbStyle;

- (void)loadCameraRollWithSuccess:(void(^)(void))success unauthorized:(void(^)(void))unauthorized;

- (NSInteger)imageCount;
- (NSString *)fileNameAtIndex:(NSInteger)index;
- (void)thumbAtIndex:(NSInteger)index completionHandler:(void(^)(UIImage *thumb))completionHandler;
- (void)imageAtIndex:(NSInteger)index completionHandler:(void(^)(UIImage *image))completionHandler;
- (void)CGImageAtIndex:(NSInteger)index completionHandler:(void(^)(CGImageRef CGImage))completionHandler;

@end
