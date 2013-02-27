//
//  OpenCvClass.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/7/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "OpenCvClass.h"
#import "Detect.h"

@implementation OpenCvClass

@synthesize delegate;



-(UIImage *)processUIImageForFace:(UIImage *)img fromFile:(NSString *)fn {
    
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    cv::Mat greyMat;
    cv::cvtColor(myCvMat, greyMat, CV_BGR2GRAY);
    
    // face detection
    IplImage myImage = myCvMat;
    rect faceDetectedInRect = [self opencvFaceDetect:&myImage fromFile:fn];
    [self.delegate setFaceRect:[self rectToCGRect:faceDetectedInRect]];
        
    return [self UIImageFromCVMat:greyMat];
    
}


-(CGRect)processUIImageForMouth:(UIImage *)greyimg fromFile:(NSString *)fn {
    
    cv::Mat mygreyCvMat = [self cvGreyMatFromUIImage:greyimg];
    
    // mouth detection
    IplImage myImage = mygreyCvMat;
    rect mouthDetectedInRect = [self opencvMouthDetect:&myImage fromFile:fn];
    
    return [self rectToCGRect:mouthDetectedInRect];
}



- (rect) opencvFaceDetect:(IplImage *)myImage fromFile:(NSString *)fn  {
    // Load XML
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    rect myRect;
    Detect(myImage, [path cStringUsingEncoding:NSUTF8StringEncoding], &myRect, "Face", [fn UTF8String]);
    return myRect;
}


- (rect) opencvMouthDetect:(IplImage *)myImage fromFile:(NSString *)fn  {
    // Load XML
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_mouth" ofType:@"xml"];
    rect myRect;
    Detect(myImage, [path cStringUsingEncoding:NSUTF8StringEncoding], &myRect, "Mouth", [fn UTF8String]);
    return myRect;
}



-(CGRect) rectToCGRect:(rect) r {
    return CGRectMake(r.x, r.y, r.width, r.height);
}



-(UIImage *)edgeDetectReturnOverlay:(UIImage *)img {
    cv::Mat myCvMat = [self cvGreyMatFromUIImage:img];
    cv::Mat edges;
    cv::Canny(myCvMat, edges, 30, 255);
    myCvMat = myCvMat - edges;
    
    return [self UIImageFromCVMat:myCvMat];
}

-(UIImage *)edgeDetectReturnEdges:(UIImage *)img {
    cv::Mat myCvMat = [self cvGreyMatFromUIImage:img];
    cv::Mat edges;
    cv::Canny(myCvMat, edges, 30, 255);
    
    return [self UIImageFromCVMat:edges];
}

-(UIImage *)edgeMeanShiftDetectReturnEdges:(UIImage *)origimg {
    cv::Mat myCvMat = [self cvGreyMatFromUIImage:origimg];
    cv::Mat bgr;
    cv::cvtColor(myCvMat, bgr, CV_GRAY2BGR);
    
    //cv::blur(bgr, bgr, cv::Size(2,2));
    //return [self UIImageFromCVMat:bgr];
    
    
    cv::pyrMeanShiftFiltering(bgr.clone(), bgr, 10, 10, 3);
    //cv::cvtColor(bgr, bgr, CV_BGR2GRAY);
    return [self UIImageFromCVMat:bgr];
    
    cv::cvtColor(bgr, bgr, CV_BGR2GRAY);
    cv::Mat edges;
    cv::Canny(bgr, edges, 30, 255);
    
    
    
    return [self UIImageFromCVMat:bgr-edges];

}




- (cv::Mat)cvGreyMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    bitmapInfo);                // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
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
    CGBitmapInfo bitmapInfo;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        bitmapInfo,                                 // bitmap info
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





-(BOOL)Search2DImage:(UIImage *)objectImage inside:(UIImage *)sceneImage {
    
    cv::Mat img_object = [self cvMatFromUIImage:objectImage];
    cv::Mat img_scene = [self cvGreyMatFromUIImage:sceneImage];
    
    cv::cvtColor(img_object, img_object, CV_BGR2GRAY);
    //cv::cvtColor(img_scene, img_scene, CV_BGR2GRAY);
    
    int minHessian = 100;
    cv::SurfFeatureDetector detector( minHessian );
    
    std::vector<cv::KeyPoint> keypoints_object, keypoints_scene;
    
    detector.detect( img_object, keypoints_object );
    detector.detect( img_scene, keypoints_scene );
    
    cv::SurfDescriptorExtractor extractor;
    cv::Mat descriptors_object, descriptors_scene;
    
    extractor.compute( img_object, keypoints_object, descriptors_object );
    extractor.compute( img_scene, keypoints_scene, descriptors_scene );
    
    
    cv::FlannBasedMatcher matcher;
    std::vector< cv::DMatch > matches;
    matcher.match( descriptors_object, descriptors_scene, matches );
    
    double max_dist = 0; double min_dist = 100;
    
    for( int i = 0; i < descriptors_object.rows; i++ )
    { double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    printf("-- objects  : %d \n\n",descriptors_object.rows);
    
    std::vector< cv::DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ ) {
        if( matches[i].distance < 2.0*min_dist ) {
            good_matches.push_back( matches[i]);
            
        } else {
           
        }
    }
    
        
    return YES;
    
}



@end
