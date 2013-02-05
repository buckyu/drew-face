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
    NSString *testFileName = @"testimage.jpg";
    UIImage *testimage;
    int w;
    int h;
    CGFloat scaleDownfactor;
    int orientation = 0;
    
    // load test input file and display on screen in UIImageView *iv
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *testFilePath = [docsDirectory stringByAppendingPathComponent:testFileName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:testFilePath]) {
        testimage = [UIImage imageWithContentsOfFile:testFilePath];
        NSData *testimageNSData = [NSData dataWithContentsOfFile:testFilePath];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
        NSDictionary *metadata = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
        orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        BOOL DoRotateImage90Degrees = NO;
        if (orientation>=5) {
            DoRotateImage90Degrees = YES;
        }
        iv = [[UIImageView alloc] initWithImage:testimage];
        if (DoRotateImage90Degrees) {
            h = (int)testimage.size.width;
            w = (int)testimage.size.height;
        } else {
            w = (int)testimage.size.width;
            h = (int)testimage.size.height;
        }
        scaleDownfactor = (w>h)? 320.0/w : 320.0/h;
        iv.frame = CGRectMake(0, 100, w*scaleDownfactor, h*scaleDownfactor);
        [self.view addSubview:iv];
    } else {
        // exit, can not continue
        NSLog(@"%@ not in Documents Directory",testFileName);
        return;
    }
    
    
    // "Bion's been working on a .NET Jpeg->pixel decoder in YCbCr for production use."
    // Since the production system will have YCbCr available, iOS can be used here to get pixel values
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(testimage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);
    
    // to test and prove we have a copy of the pixels in BGRA format for the original JPEG
    uint8_t *mutablebuffer = (uint8_t *)malloc(w*h*4);
    memcpy(&mutablebuffer[0],testimagedata,w*h*4);
    for (int i=0; i<h/2; i++) {
        for (int j=0; j<w; j++) {
            // do something noticeable with the pixels
            //*(mutablebuffer + i*w*4 + j*4 + 0) = 0xff;
        }
    }
    CFRelease(pixelData);

    
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(testimage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(testimage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer, w, h, 8, w*4,colorspaceRef, bitmapInfo);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    
    UIImage *modifiedImage;
    if (orientation==6) {
        modifiedImage = [self imageRotate:[UIImage imageWithCGImage:newImageRef] rotatedby:M_PI/2.0];
        iv.frame = CGRectMake(0, 100, iv.frame.size.height, iv.frame.size.width);
    } else {
        modifiedImage = [self imageRotate:[UIImage imageWithCGImage:newImageRef] rotatedby:0.0];
    }
    
    
    iv.image = modifiedImage;
    
    free(mutablebuffer);
}


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




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
