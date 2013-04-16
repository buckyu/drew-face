//
//  FindMouthsViewController+CPlusPlusExtensions.m
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FindMouthsViewController+CPlusPlusExtensions.h"
#import "DrewFaceDetectPart2.h"
@implementation FindMouthsViewController (CPlusPlusExtensions)

#define GET_PIXELORIG(X,Y,Z) testimagedataOrig[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXEL(X,Y,Z) testimagedata[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD1(X,Y,Z) testimagedataMod1[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD2(X,Y,Z) testimagedataMod2[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define PIXEL_INDEX(X,Y) Y *(int)mouthImage.size.width + X

#define DELTA_ALLOWED_FOR_WHITE 100
#define THRESHOLD_WHITE_BLACK 10
#define MIN_Y_BRIGHTNESS_THRESHOLD 150
#define MAX_Y_FOR_DARK_THRESHOLD 250
#define MAX_CR_THRESHOLD_WHITETEETH 20
#define MAX_CB_THRESHOLD_WHITETEETH 10
#define EXPECT_TEETH 5
#define NUMBER_OF_LINES 10000
#define MIN_TOOTH_SIZE 20
#define MAX_TOOTH_SIZE 50
#define MIN_DARK_SIZE 1
#define MAX_DARK_SIZE 4



// Drew's Algorithm to go here:
-(UIImage *)lookForTeethInMouthImage:(UIImage*)mouthImage {
    
    
    ocv = [OpenCvClass new];
    /*uint8_t *testimagedata = (uint8_t*)malloc(mouthImage.size.width * mouthImage.size.height *4);
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(mouthImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedataOrig = CFDataGetBytePtr(pixelData);
    
    memcpy(testimagedata, testimagedataOrig, mouthImage.size.height * mouthImage.size.width * 4);
    CFRelease(pixelData);*/

    cv::Mat mouthImageMatrix = [OpenCvClass cvMatFromUIImage:mouthImage];
    
    std::vector<NotCGPoint> *ptrSolution = findTeethArea(mouthImageMatrix);
    std::vector<NotCGPoint> solution = *ptrSolution;
    if (solution.size()==0) return mouthImage;
    //assert(solution.size()!=0);

        
    
    //draw on top of the image, this is purely for debugging
    /*__block UIImage *outImage;
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContext(mouthImage.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, 0.0, mouthImage.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGRect rect1 = CGRectMake(0, 0, mouthImage.size.width, mouthImage.size.height);
        CGContextDrawImage(context, rect1, mouthImage.CGImage);
        
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
        CGContextSetFillColorWithColor(context, color.CGColor);
        outImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });*/
    
    
    // show image on iPhone view
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(mouthImage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(mouthImage.CGImage);
    CGContextRef newContextRef = CGBitmapContextCreate(NULL, mouthImage.size.width, mouthImage.size.height, 8, mouthImage.size.width*4,colorspaceRef, bitmapInfo);
    CGContextScaleCTM(newContextRef, 1.0, -1.0);
    CGContextTranslateCTM(newContextRef, 0.0, -mouthImage.size.height);
    UIGraphicsPushContext(newContextRef);
    [mouthImage drawAtPoint:CGPointZero];
    UIGraphicsPopContext();
    
    UIColor *greenColor = [UIColor greenColor];
    CGContextSetStrokeColorWithColor(newContextRef, greenColor.CGColor);
    CGContextSetLineWidth(newContextRef, 3.0);

    CGMutablePathRef myRef = CGPathCreateMutable();
    NotCGPoint leftmost = solution[0];
    CGPathMoveToPoint(myRef, NULL, leftmost.x, leftmost.y);
    for (int i = 0; i < solution.size(); i++) {
        NotCGPoint pt = solution[i];
        CGPathAddLineToPoint(myRef, NULL, pt.x, pt.y);
        
    }
    CGPathAddLineToPoint(myRef, NULL, leftmost.x, leftmost.y);
    CGContextAddPath(newContextRef, myRef);
    CGContextStrokePath(newContextRef);
    CGPathRelease(myRef);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show MODIFIED  image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    
    
    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);
    
        
    
    return modifiedImage;
    //return [ocv edgeMeanShiftDetectReturnEdges:mouthImage];*/
    
}
@end
