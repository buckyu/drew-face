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


@interface OpenCvClass : NSObject {
    
    __weak id <OpenCvClassDelegate> delegate;
    
}

@property (weak) id <OpenCvClassDelegate> delegate;

-(UIImage *)processUIImageForFace:(UIImage *)img;
-(CGRect)processUIImageForMouth:(UIImage *)img;

-(UIImage *)edgeDetectReturnOverlay:(UIImage *)img;
-(UIImage *)edgeDetectReturnEdges:(UIImage *)img;

@end
