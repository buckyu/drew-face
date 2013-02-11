//
//  OpenCvClass.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/7/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "OpenCvClass.h"
#import "FaceDetect.h"

@implementation OpenCvClass

@synthesize delegate;

-(void)testCppFunc {
    NSLog(@"hello");
    #ifdef __cplusplus
    NSLog(@"hi");
    #endif
}



-(UIImage *)processUIImage:(UIImage *)img {
    
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    cv::Mat greyMat;
    cv::cvtColor(myCvMat, greyMat, CV_BGR2GRAY);
    
    // face detection
    
    IplImage myImage = greyMat;
    //IplImage myImage = myCvMat;
    [self opencvFaceDetect:&myImage];
    
        
    return [self UIImageFromCVMat:greyMat];
    
}


-(CGRect) rectToCGRect:(rect) r {
    return CGRectMake(r.x, r.y, r.width, r.height);
}


- (void) opencvFaceDetect:(IplImage *)myImage  {    
    // Load XML
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    
    rect myRect;
    
    faceDetect(myImage, [path cStringUsingEncoding:NSUTF8StringEncoding], &myRect);

    
    [self.delegate setFaceRect:[self rectToCGRect:myRect]];
    
    
}


























- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



@end
