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
    
}


-(IBAction)LoadTestImageJPEGButtonPressed {
    
    // iOS UIImageView for debug and showing results on screen
    UIImageView *iv;
    
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
        // check for 
        NSData *testimageNSData = [NSData dataWithContentsOfFile:testFilePath];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
        NSDictionary *metadata = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
        orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        if (orientation==6) {
            // rotate CGImageRef data as well as the UIImage
            testimage = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0]];
        } else if (!orientation) {
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
    
    
    // "Bion's been working on a .NET Jpeg->pixel decoder in YCbCr for production use."
    // Since the production system will have YCbCr available, iOS can be used here to get pixel values
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(testimage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);
 
    
    // convert to grayscale for face detection
    // Y = 0.299R + 0.587G + 0.114B
    uint8_t *mutablebuffer = (uint8_t *)malloc(w*h*4);
    memcpy(&mutablebuffer[0],testimagedata,w*h*4);
    for (int i=0; i<h; i++) {
        for (int j=0; j<w; j++) {
            uint8_t y = 0.299 * *(mutablebuffer + i*w*4 + j*4 + 0) + 0.587 * *(mutablebuffer + i*w*4 + j*4 + 1) + 0.114 * *(mutablebuffer + i*w*4 + j*4 + 3);
            *(mutablebuffer + i*w*4 + j*4 + 0) = y;
            *(mutablebuffer + i*w*4 + j*4 + 1) = y;
            *(mutablebuffer + i*w*4 + j*4 + 2) = y;
        }
    }
    CFRelease(pixelData);

    
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(testimage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(testimage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer, w, h, 8, w*4,colorspaceRef, bitmapInfo);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show grayscale image om iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    iv.image = modifiedImage;
    
    free(mutablebuffer);
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
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   CGImageGetBitmapInfo(imgRef));
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
