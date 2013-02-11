//
//  DrewFaceViewController.h
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/4/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

#import "OpenCvClass.h"


@interface DrewFaceViewController : UIViewController <OpenCvClassDelegate> {
    
    CGFloat scaleDownfactor;
    
    // iOS UIImageView for debug and showing results on screen
    UIImageView *iv;
    UIImageView *ivFaceOnly;

    // OpenCV processing class
    OpenCvClass *ocv;
    
    CGRect faceRectInView;
    CGRect faceRectInOrigImage;


}

-(IBAction)LoadTestImageJPEGButtonPressed;
-(void)setFaceRect:(CGRect)facerectArea;

@end
