//
//  OpenCvClass.h
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/7/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//
@protocol OpenCvClassDelegate
-(void)setFaceRect:(CGRect)faceRect;
@end


#import <Foundation/Foundation.h>

#import <opencv2/highgui/highgui_c.h>
#import <opencv2/imgproc/imgproc_c.h>

#import <opencv2/features2d/features2d.hpp>
#import <opencv2/nonfree/features2d.hpp>
#import "Detect.h"


@interface OpenCvClass : NSObject {
    
    __weak id <OpenCvClassDelegate> delegate;
    
}

@property (weak) id <OpenCvClassDelegate> delegate;

-(UIImage *)processUIImageForFace:(UIImage *)img fromFile:(const char*)fn outRect:(rect*) outRect;
-(CGRect)processUIImageForMouth:(UIImage *)img fromFile:(const char*)fn;

-(UIImage *)edgeDetectReturnOverlay:(UIImage *)img;
-(UIImage *)edgeDetectReturnEdges:(UIImage *)img;
-(UIImage *)edgeMeanShiftDetectReturnEdges:(UIImage *)origimg;

-(BOOL)Search2DImage:(UIImage *)objectImage inside:(UIImage *)sceneImage;

-(UIImage *)exposureCompensate:(UIImage *)origimg;


// do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
-(UIImage *)greyTheImage:(UIImage *)origimg;

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

@end