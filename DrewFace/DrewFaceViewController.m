//
//  DrewFaceViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/4/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "DrewFaceViewController.h"

@interface DrewFaceViewController ()

@end

@implementation DrewFaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    ocv = [OpenCvClass new];
    
}


-(IBAction)LoadTestImageJPEGButtonPressed {
    
    [iv removeFromSuperview];
    
    // test input image in Documents Directory of iPhone
    NSString *testFileName = @"testimage1.jpg";
    UIImage *testimage;
    int w;
    int h;
    CGFloat scaleDownfactor;
    int orientation = 0;
    
    // load test input file
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *testFilePath = [docsDirectory stringByAppendingPathComponent:testFileName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:testFilePath]) {
        testimage = [UIImage imageWithContentsOfFile:testFilePath];
        

        // check for orientation
        NSData *testimageNSData = [NSData dataWithContentsOfFile:testFilePath];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
        CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
        NSDictionary *metadata = (__bridge NSDictionary *) dictRef;
        CFRelease(source);
        CFRelease(dictRef);
        orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        
        if (orientation==6) {
            // rotate CGImageRef data as well as the UIImage
            CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0];
            testimage = [UIImage imageWithCGImage:rotatedImageRef];
            CGImageRelease(rotatedImageRef);
        } else if (orientation>0) {
            NSLog(@"Orientation not 0 or 6. Need to accommodate here");
        }
        
        
        iv = [[UIImageView alloc] initWithImage:testimage];
        w = (int)testimage.size.width;
        h = (int)testimage.size.height;
        // scale image for iPhone screen keeping aspect ratio
        scaleDownfactor = (w>h)? 320.0/w : 320.0/h;
        iv.frame = CGRectMake(0, 100, w*scaleDownfactor, h*scaleDownfactor);
        [self.view addSubview:iv];
    } else {
        // exit, file not found, can not continue
        NSLog(@"%@ not in Documents Directory",testFileName);
        return;
    }
    
    ocv = [OpenCvClass new];
    testimage = [ocv processUIImage:testimage];
    
    iv.image = testimage;
    
    

}






// helper functions for rotating UIImage and CGImageRef

- (UIImage *)imageRotate:(UIImage *)origImage rotatedby:(CGFloat)rads
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,origImage.size.width, origImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(rads);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, rads);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-origImage.size.width / 2, -origImage.size.height / 2, origImage.size.width, origImage.size.height), [origImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
    
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angleInRadians
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
	CGColorSpaceRelease(colorSpace);
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




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
