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


// do not know why but CGImageCreateWithImageInRect() can not be pixel mapped?? 
-(UIImage *)greyTheImage:(UIImage *)origimg {
    cv::Mat greyMat = [self cvGreyMatFromUIImage:origimg];
    return [self UIImageFromCVMat:greyMat];
}

-(UIImage *)colorTheImage:(UIImage *)origimg {
    cv::Mat myMat = [self cvMatFromUIImage:origimg];
    return [self UIImageFromCVMat:myMat];
}

-(UIImage *)BGR2BGRATheImage:(UIImage *)origimg {
    cv::Mat myMat = [self cvMatFromUIImage:origimg];
    cv::cvtColor(myMat, myMat, CV_BGR2BGRA);
    return [self UIImageFromCVMat:myMat];
}

-(UIImage *)BGRA2BGRTheImage:(UIImage *)origimg {
    cv::Mat myMat = [self cvMatFromUIImage:origimg];
    cv::cvtColor(myMat, myMat, CV_BGRA2BGR);
    return [self UIImageFromCVMat:myMat];
}



-(UIImage *)processUIImageForFace:(UIImage *)img fromFile:(NSString *)fn {
    
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    cv::Mat greyMat;
    cv::cvtColor(myCvMat, greyMat, CV_BGR2GRAY);
    
    // face detection
    IplImage myImage = myCvMat;
    rect faceDetectedInRect = [self opencvFaceDetect:&myImage fromFile:fn];
    [self.delegate setFaceRect:[self rectToCGRect:faceDetectedInRect]];
        
    //return [self UIImageFromCVMat:greyMat];
    return img;
}


-(CGRect)processUIImageForMouth:(UIImage *)colorimg fromFile:(NSString *)fn {
    
    cv::Mat myCvMat = [self cvMatFromUIImage:colorimg];
    
    // mouth detection
    IplImage myImage = myCvMat;
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
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    cv::Mat edges;
    cv::cvtColor(myCvMat, edges, CV_BGR2GRAY);
    cv::Canny(edges, edges, 30, 255);
    cv::cvtColor(edges, edges, CV_GRAY2BGRA);
    myCvMat = myCvMat - edges;
    
    return [self UIImageFromCVMat:myCvMat];
}

-(UIImage *)edgeDetectReturnEdges:(UIImage *)img {
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    
    cv::Mat edges;
    //cv::blur(myCvMat, edges, cv::Size(4,4));
    cv::cvtColor(myCvMat, myCvMat, CV_BGRA2BGR);
    cv::pyrMeanShiftFiltering(myCvMat.clone(), myCvMat, 10, 10, 4);
    cv::cvtColor(myCvMat, myCvMat, CV_BGR2BGRA);
    
    //cv::Canny(edges, edges, 40, 120, 3, true);
    //cv::cvtColor(edges, edges, CV_BGR2BGRA);
    return [self UIImageFromCVMat:myCvMat];
}

-(UIImage *)edgeMeanShiftDetectReturnEdges:(UIImage *)origimg {
    cv::Mat myCvMat = [self cvMatFromUIImage:origimg];
    //cv::Mat bgr;
    //cv::cvtColor(myCvMat, bgr, CV_GRAY2BGR);
    
    //cv::blur(myCvMat, myCvMat, cv::Size(4,4));
    //return [self UIImageFromCVMat:myCvMat];
    
    cv::cvtColor(myCvMat, myCvMat, CV_BGRA2BGR);
    cv::pyrMeanShiftFiltering(myCvMat.clone(), myCvMat, 10, 10, 4);
    cv::cvtColor(myCvMat, myCvMat, CV_BGR2BGRA);
    return [self UIImageFromCVMat:myCvMat];
    
//    cv::cvtColor(bgr, bgr, CV_BGR2GRAY);
//    cv::Mat edges;
//    cv::Canny(bgr, edges, 30, 255);
//    
//    
//    
//    return [self UIImageFromCVMat:bgr-edges];

}


-(UIImage *)exposureCompensate:(UIImage *)origimg {
    CIContext *context = [CIContext contextWithOptions:nil]; 
    CIImage *cii = [CIImage imageWithCGImage:origimg.CGImage];
    
    CIFilter *exposureAdjustmentFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
    [exposureAdjustmentFilter setDefaults];
    [exposureAdjustmentFilter setValue:cii forKey:@"inputImage"];
    [exposureAdjustmentFilter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputEV"];
    CIImage *outputImage = [exposureAdjustmentFilter valueForKey:@"outputImage"];
    
    
    CGImageRef cgImageRef = [context createCGImage:outputImage fromRect:CGRectMake(0, 0, origimg.size.width, origimg.size.height)];
    UIImage *ri = [UIImage imageWithCGImage:cgImageRef];
    return ri;
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
