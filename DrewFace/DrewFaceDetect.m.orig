//
//  DrewFaceDetect.m
//  DrewFace
//
//  Created by Drew Crawford on 3/28/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "DrewFaceDetect.h"
#import <ImageIO/ImageIO.h>
#import "OpenCvClass.h"



#if DONT_PORT
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
#import "FindMouthsViewController+CPlusPlusExtensions.h"
#endif




@interface DrewFaceDetect() {

}
@end
@implementation DrewFaceDetect



+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    // OCV exposure compensator
    
	return newImage;
}

+ (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angleInRadians
{
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(imgRef);
    CGBitmapInfo bitinfo = CGImageGetBitmapInfo(imgRef);
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   bitinfo);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);
    
	return rotatedImage;
}

+(void) setupStructures {
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


+ (NSMutableDictionary *)extractGeometry:(NSString *)fileNamePath {
    
    NSString *simpleFileName = [fileNamePath lastPathComponent];


    
    // Find Mouths in original images here
    
    // Orient images for face detection (EXIF Orientation = 0)
    NSData *testimageNSData = [NSData dataWithContentsOfFile:fileNamePath];
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
    CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
    NSDictionary *metadata = (__bridge NSDictionary *) dictRef;
    int orientation = [[metadata valueForKey:@"Orientation"] integerValue];
    CFRelease(dictRef);
    CFRelease(source);
    
    UIImage *testimage = [UIImage imageWithContentsOfFile:fileNamePath];
    if (orientation==6) {
        // rotate CGImageRef data
        CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0];
        testimage = [UIImage imageWithCGImage:rotatedImageRef];
        CGImageRelease(rotatedImageRef);
    } else if (orientation == 3) {
        CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:M_PI];
        testimage = [UIImage imageWithCGImage:rotatedImageRef];
        CGImageRelease(rotatedImageRef);
    } else if (orientation>1) {
        NSLog(@"%@ Orientation %d not 0, 1 or 6. Need to accommodate here",fileNamePath,orientation);
    }
    
    // Scale down to 1024 max dimension for speed optimization of face detect
    int w = (int)testimage.size.width;
    int h = (int)testimage.size.height;
    int maxDimension = w>h? w : h;
    CGFloat facedetectScaleFactor = 1.0;
    if (maxDimension > 1024) {
        facedetectScaleFactor = 1024.0 / (CGFloat)maxDimension;
    }
    CGSize scaledDownSize = CGSizeMake(facedetectScaleFactor*w, facedetectScaleFactor*h);
    UIImage *scaledImage = [self imageWithImage:testimage scaledToSize:scaledDownSize];
    
    
    // search for face in scaledImage
    // OpenCV Processing Called Here for Face Detect
    
    
    // testimage - faceRectInScaledOrigImage is set by delegate method call
    OpenCvClass *ocv = [OpenCvClass new];
    rect faceRect;
    testimage = [ocv processUIImageForFace:scaledImage fromFile:fileNamePath outRect:&faceRect];
    if ((faceRect.width == 0) || (faceRect.height == 0)) {
        NSLog(@"NO FACE in %@",fileNamePath);
        return nil;
    }
    
    
    // extract bottom half of face from COLOR image
    CGImageRef cutBottomHalfFaceRef = CGImageCreateWithImageInRect(testimage.CGImage, CGRectMake((int)(faceRect.x), (int)(faceRect.y+0.66*faceRect.height), (int)(faceRect.width), (int)(0.34*faceRect.height)));
    
    
    // locate mouth in bottom half of greyscale face image
    UIImage *bottomhalffaceImage = [UIImage imageWithCGImage:cutBottomHalfFaceRef];
    // do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
    // bottomhalffaceImage = [ocv greyTheImage:bottomhalffaceImage];
    
    
    //int mouthIdx = -1;
    CGRect mouthRectInBottomHalfOfFace = CGRectMake(0,0,0,0);
    
    
    // OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
    mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:bottomhalffaceImage fromFile:fileNamePath];
    // BruteForce Processing Called Here - search for mouth in bottom half of greyscale face
    // using MODELMOUTHxxx.png files in /MODEL_MOUTHS/
    //[self processUIImageForMouth:bottomhalffaceImage returnRect:&mouthRectInBottomHalfOfFace closestMouthMatch:&mouthIdx fileName:fileName];
    
    
    if ((mouthRectInBottomHalfOfFace.size.width == 0) || (mouthRectInBottomHalfOfFace.size.height == 0)) {
        NSLog(@"NO MOUTH in %@",fileNamePath);
#if DONT_PORT
        [manager copyItemAtPath:fileNamePath toPath:[NoMouthDir stringByAppendingPathComponent:simpleFileName] error:nil];
#endif
        return nil;
    }
    
    // extract mouth from face
    CGImageRef cutMouthRef = CGImageCreateWithImageInRect(bottomhalffaceImage.CGImage, CGRectMake(mouthRectInBottomHalfOfFace.origin.x, mouthRectInBottomHalfOfFace.origin.y, mouthRectInBottomHalfOfFace.size.width, mouthRectInBottomHalfOfFace.size.height));
    UIImage *mouthImage = [UIImage imageWithCGImage:cutMouthRef];
    CGImageRelease(cutMouthRef);
    
    UIImage *processedMouthImage = nil;
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
        processedMouthImage = [ocv edgeDetectReturnOverlay:mouthImage];
    }
    
    // write mouth images to EXTRACTED_MOUTHS directory
#if DONT_PORT
    NSData *dataToWrite = UIImagePNGRepresentation(mouthImage);
    NSString *thumbPath = [extractedMouthsDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite writeToFile:thumbPath atomically:YES];
#endif
    
    //processedMouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
        
#ifdef DONT_PORT
        FindMouthsViewController *dvc = [[FindMouthsViewController alloc] init];
        processedMouthImage = [dvc lookForTeethInMouthImage:mouthImage];
#endif
        //processedMouthImage = [self lookForTeethInMouthImage:mouthImage];
        
        if (!((processedMouthImage.size.width>0) && (processedMouthImage.size.height>0))) {
            NSLog(@"NO TEETH in %@",fileNamePath);
            return nil;
        }
    }
    
    // convert to RGB since following code is RGB based
    processedMouthImage = [ocv BGRA2BGRTheImage:processedMouthImage];
    
    // color images here of mouth area
    
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(processedMouthImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);
    
    w = (int)processedMouthImage.size.width;
    h = (int)processedMouthImage.size.height;
    uint8_t *mutablebuffer = (uint8_t *)malloc(w*h*3);
    uint8_t *mutablebuffer4 = (uint8_t *)malloc(w*h*4);
    
    memcpy(&mutablebuffer[0],testimagedata,w*h*3);
    
    for (int i=0; i<h; i++) {
        for (int j=0; j<w; j++) {
            
            int sum = 0;
            sum += *(mutablebuffer + i*w*3 + j*3 + 0);
            sum += *(mutablebuffer + i*w*3 + j*3 + 1);
            sum += *(mutablebuffer + i*w*3 + j*3 + 2);
            
            //if (sum > (3*128)) {
            if (1) {
                memcpy((mutablebuffer4 + i*w*4 + j*4), (mutablebuffer + i*w*3 + j*3), 3);
            } else {
                bzero((mutablebuffer4 + i*w*4 + j*4), 3);
            }
            
        }
    }
    CFRelease(pixelData);
    
    // show image on iPhone view
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(processedMouthImage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(processedMouthImage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer4, w, h, 8, w*4,colorspaceRef, bitmapInfo);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show MODIFIED  image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);
    
    free(mutablebuffer);
    free(mutablebuffer4);
    
    
    
    
    
    
    
    
    
    
    
    
    // write mouth images to EXTRACTED_MOUTHS_EDGES directory
    dataToWrite = UIImagePNGRepresentation(modifiedImage);
#ifdef DONT_PORT
    thumbPath = [extractedMouthsEdgesDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
#else
    thumbPath = some reasonable path?
#endif
    [dataToWrite writeToFile:thumbPath atomically:YES];
    
    
    
    NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     fileNamePath,@"originalFileName",
                                     [NSNumber numberWithFloat:facedetectScaleFactor],@"facedetectScaleFactor",
                                     [NSNumber numberWithFloat:faceRect.x],@"facedetectX",
                                     [NSNumber numberWithFloat:faceRect.y],@"facedetectY",
                                     [NSNumber numberWithFloat:faceRect.width],@"facedetectW",
                                     [NSNumber numberWithFloat:faceRect.height],@"facedetectH",
                                     [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.origin.x],@"mouthdetectX",
                                     [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.origin.y],@"mouthdetectY",
                                     [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.size.width],@"mouthdetectW",
                                     [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.size.height],@"mouthdetectH",
                                     nil];
    return fileInfo;
}
@end
