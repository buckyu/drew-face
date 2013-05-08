//
//  DrewFaceDetect.m
//  DrewFace
//
//  Created by Drew Crawford on 3/28/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#if DONT_PORT
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#endif

#import "FindMouthsViewController+CPlusPlusExtensions.h"

#include "DrewFaceDetect.h"
#include <opencv2/imgproc/imgproc_c.h>
#include "exif-data.h"
#include <stdio.h>
#include "OpenCvClass.h"
#include "jpeglib.h"
#include "jerror.h"

#if DONT_PORT
#import "DrewFaceAppDelegate.h"
NSString *docsDir;
NSString *originalDir;
NSString *originalThumbsDir;
NSString *extractedMouthsDir;
NSString *extractedMouthsEdgesDir;

NSString *NoFaceDir;
NSString *NoMouthDir;

NSString *testDir;
NSString *modelMouthDir;
NSFileManager *manager;
#import "FindMouthsViewController.h"
#endif

@implementation DrewFaceDetect

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return newImage;
}

@end

void setupStructures() {
#ifdef DONT_PORT
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        originalDir = [docsDir stringByAppendingPathComponent:@"ORIGINAL"];
        originalThumbsDir = [docsDir stringByAppendingPathComponent:@"ORIGINAL_THUMBS"];
        [manager removeItemAtPath:originalThumbsDir error:NULL];
        if (![manager fileExistsAtPath:originalThumbsDir]) {
            [manager createDirectoryAtPath:originalThumbsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        extractedMouthsDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS"];
        [manager removeItemAtPath:extractedMouthsDir error:NULL];
        if (![manager fileExistsAtPath:extractedMouthsDir]) {
            [manager createDirectoryAtPath:extractedMouthsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        extractedMouthsEdgesDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS_EDGES"];
        [manager removeItemAtPath:extractedMouthsEdgesDir error:NULL];
        if (![manager fileExistsAtPath:extractedMouthsEdgesDir]) {
            [manager createDirectoryAtPath:extractedMouthsEdgesDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        NoFaceDir = [docsDir stringByAppendingPathComponent:@"NO_FACE_FOUND"];
        [manager removeItemAtPath:NoFaceDir error:NULL];
        if (![manager fileExistsAtPath:NoFaceDir]) {
            [manager createDirectoryAtPath:NoFaceDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        NoMouthDir = [docsDir stringByAppendingPathComponent:@"NO_MOUTH_FOUND"];
        [manager removeItemAtPath:NoMouthDir error:NULL];
        if (![manager fileExistsAtPath:NoMouthDir]) {
            [manager createDirectoryAtPath:NoMouthDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    });

#endif
}





NSMutableDictionary *objcDictOfStruct(FileInfo *dict) {
    if(!dict) {
        return nil;
    }
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];

    ret[@"originalFileName"] = [NSString stringWithCString:dict->originalFileNamePath encoding:NSMacOSRomanStringEncoding];
    NSMutableArray *points = [[NSMutableArray alloc] init];
    for(std::vector<NotCGPoint>::size_type i = 0; i < dict->points->size(); ++i) {
        NotCGPoint point = (*dict->points)[i];
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y)]];
    }
    ret[@"points"] = points;
    NSMutableArray *imagePoints = [[NSMutableArray alloc] init];
    for(std::vector<NotCGPoint>::size_type i = 0; i < dict->imagePoints->size(); ++i) {
        NotCGPoint point = (*dict->imagePoints)[i];
        [imagePoints addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y)]];
    }
    ret[@"imagePoints"] = imagePoints;
    ret[@"facedetectScaleFactor"] = @(dict->facedetectScaleFactor);
    ret[@"facedetectX"] = @(dict->facedetectX);
    ret[@"facedetectY"] = @(dict->facedetectY);
    ret[@"facedetectW"] = @(dict->facedetectW);
    ret[@"facedetectH"] = @(dict->facedetectH);
    ret[@"mouthdetectX"] = @(dict->mouthdetectX);
    ret[@"mouthdetectY"] = @(dict->mouthdetectY);
    ret[@"mouthdetectW"] = @(dict->mouthdetectW);
    ret[@"mouthdetectH"] = @(dict->mouthdetectH);

    return ret;
}