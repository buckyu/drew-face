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


@interface OpenCvClass : NSObject {
    
    __weak id <OpenCvClassDelegate> delegate;
    
}

@property (weak) id <OpenCvClassDelegate> delegate;

-(UIImage *)processUIImageForFace:(UIImage *)img fromFile:(NSString *)fn;
-(CGRect)processUIImageForMouth:(UIImage *)img fromFile:(NSString *)fn;

-(UIImage *)edgeDetectReturnOverlay:(UIImage *)img;
-(UIImage *)edgeDetectReturnEdges:(UIImage *)img;
-(UIImage *)edgeMeanShiftDetectReturnEdges:(UIImage *)origimg;

-(BOOL)Search2DImage:(UIImage *)objectImage inside:(UIImage *)sceneImage;

@end
