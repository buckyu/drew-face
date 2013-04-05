//
//  DrewFaceViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/4/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "DrewFaceViewController.h"
#import "DrewFaceDetect.h"
@interface DrewFaceViewController () {

}

@end

@implementation DrewFaceViewController

- (void)viewDidLoad
{
    setupStructures();

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}



-(IBAction)FindMouthsInOriginalPressed {
    
    FindMouthsViewController *fmvc = [FindMouthsViewController new];
    fmvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:fmvc animated:YES completion:NULL];
    
}











-(IBAction)LoadTestImageJPEGButtonPressed {
    
    // test input image in Documents Directory of iPhone
    NSString *testFileName = @"testimage.jpg";
    UIImage *testimage;
    int w;
    int h;
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
        orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        CFRelease(dictRef);
        CFRelease(source);
        
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
            NSLog(@"Orientation %d not 0, 1 or 6. Need to accommodate here",orientation);
        }

        
        [iv removeFromSuperview];
        iv = [[UIImageView alloc] initWithImage:testimage];
        w = (int)testimage.size.width;
        h = (int)testimage.size.height;
        // scale image for iPhone screen keeping aspect ratio
        scaleDownfactor = (w>h)? 320.0/w : 320.0/h;
        iv.frame = CGRectMake(0, 80, w*scaleDownfactor, h*scaleDownfactor);
        [self.view addSubview:iv];
    } else {
        // exit, file not found, can not continue
        NSLog(@"%@ not in Documents Directory",testFileName);
        return;
    }
    
    // OpenCV Processing Called Here for Face Detect
    ocv = [OpenCvClass new];
    ocv.delegate = self;
    rect faceRect;
    cv::Mat mat = [OpenCvClass cvMatFromUIImage:testimage];
    testimage = [OpenCvClass UIImageFromCVMat:*[ocv processUIImageForFace:&mat fromFile:[testFileName cStringUsingEncoding:NSMacOSRomanStringEncoding] outRect:&faceRect]];
    
    // replace image in UIImageView with greyscale image from OpenCV
    iv.image = testimage;
  
    
    // red shadow around face detection area
    UIView *faceRectAreaView = [self.view viewWithTag:100];
    if (!faceRectAreaView) {
        faceRectAreaView = [UIView new];
        faceRectAreaView.tag = 100;
        faceRectAreaView.backgroundColor = [UIColor redColor];
        faceRectAreaView.alpha = 0.2;
        [self.view addSubview:faceRectAreaView];
    }
    faceRectAreaView.frame = faceRectInView;
    [self.view bringSubviewToFront:faceRectAreaView];
    
    
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(testimage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);
    
    
    uint8_t *mutablebuffer = (uint8_t *)malloc(w*h*4);
    memcpy(&mutablebuffer[0],testimagedata,w*h*1);
    for (int i=0; i<h; i++) {
        for (int j=0; j<w; j++) {
            
            // do something with pixels here
        
        }
    }
    CFRelease(pixelData);
    
    
    
    // show greyscale image on iPhone view
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(testimage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(testimage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer, w, h, 8, w*1,colorspaceRef, bitmapInfo);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show MODIFIED grayscale image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    iv.image = modifiedImage;
    
    // extract face from grey image
    CGImageRef cutFaceRef = CGImageCreateWithImageInRect(newImageRef, faceRectInOrigImage);
    
    // extract bottom half of face from grey image
    CGImageRef cutBottomHalfFaceRef = CGImageCreateWithImageInRect(newImageRef, CGRectMake(faceRectInOrigImage.origin.x, faceRectInOrigImage.origin.y+0.5*faceRectInOrigImage.size.height,faceRectInOrigImage.size.width,0.5*faceRectInOrigImage.size.height));
    
    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);

    free(mutablebuffer);
    
    
    // show extracted face on iPhone screen
    UIImage *faceImage = [UIImage imageWithCGImage:cutFaceRef];
    [ivFaceOnly removeFromSuperview];
    ivFaceOnly = [[UIImageView alloc] initWithImage:faceImage];
    ivFaceOnly.frame = CGRectMake(0, 400, ivFaceOnly.frame.size.width*scaleDownfactor, ivFaceOnly.frame.size.height*scaleDownfactor);
    [self.view addSubview:ivFaceOnly];
    CGImageRelease(cutFaceRef);
    
    
    // UIImage of bottom half of face
    UIImage *bottomhalffaceImage = [UIImage imageWithCGImage:cutBottomHalfFaceRef];
    CGImageRelease(cutBottomHalfFaceRef);
    
    // show extracted bottom half face on iPhone screen
    [ivBottomHalfFaceOnly removeFromSuperview];
    ivBottomHalfFaceOnly = [[UIImageView alloc] initWithImage:bottomhalffaceImage];
    ivBottomHalfFaceOnly.frame = CGRectMake(160, 400, bottomhalffaceImage.size.width*scaleDownfactor,bottomhalffaceImage.size.height*scaleDownfactor);
    [self.view addSubview:ivBottomHalfFaceOnly];
    

    // OpenCV Processing Called Here - search for mouth in bottom half of face

    cv::Mat img = [OpenCvClass cvMatFromUIImage:bottomhalffaceImage];
    cv::Rect mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:&img fromFile:[testFileName cStringUsingEncoding:NSMacOSRomanStringEncoding]];
    
    UIView *blackOutMouthView = [UIView new];
    blackOutMouthView.frame = CGRectMake(mouthRectInBottomHalfOfFace.x*scaleDownfactor, mouthRectInBottomHalfOfFace.y*scaleDownfactor, mouthRectInBottomHalfOfFace.width*scaleDownfactor, mouthRectInBottomHalfOfFace.height*scaleDownfactor);
    blackOutMouthView.backgroundColor = [UIColor blackColor];
    [ivBottomHalfFaceOnly addSubview:blackOutMouthView];

}




-(void)setFaceRect:(CGRect)facerectArea {
    faceRectInView = CGRectMake(facerectArea.origin.x*scaleDownfactor, 80 + facerectArea.origin.y*scaleDownfactor, facerectArea.size.width*scaleDownfactor, facerectArea.size.height*scaleDownfactor);
    faceRectInOrigImage = facerectArea;
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