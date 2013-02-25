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



-(UIImage *)processUIImageForFace:(UIImage *)img {
    
    cv::Mat myCvMat = [self cvMatFromUIImage:img];
    cv::Mat greyMat;
    cv::cvtColor(myCvMat, greyMat, CV_BGR2GRAY);
    
    // face detection
    IplImage myImage = myCvMat;
    rect faceDetectedInRect = [self opencvFaceDetect:&myImage];
    [self.delegate setFaceRect:[self rectToCGRect:faceDetectedInRect]];
        
    return [self UIImageFromCVMat:greyMat];
    
}


-(CGRect)processUIImageForMouth:(UIImage *)greyimg {
    
    cv::Mat mygreyCvMat = [self cvGreyMatFromUIImage:greyimg];
    
    // mouth detection
    IplImage myImage = mygreyCvMat;
    rect mouthDetectedInRect = [self opencvMouthDetect:&myImage];
    
    return [self rectToCGRect:mouthDetectedInRect];
}



- (rect) opencvFaceDetect:(IplImage *)myImage  {    
    // Load XML
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    rect myRect;
    Detect(myImage, [path cStringUsingEncoding:NSUTF8StringEncoding], &myRect);
    return myRect;
}


- (rect) opencvMouthDetect:(IplImage *)myImage  {
    // Load XML
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_mouth" ofType:@"xml"];
    rect myRect;
    Detect(myImage, [path cStringUsingEncoding:NSUTF8StringEncoding], &myRect);
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
    cv::Mat sceneMat = [self cvGreyMatFromUIImage:sceneImage];
    cv::Mat objectMat = [self cvGreyMatFromUIImage:objectImage];
    //cv::cvtColor(sceneMat, sceneMat, CV_GRAY2BGR);
    //cv::cvtColor(objectMat, objectMat, CV_GRAY2BGR);
    
    BOOL objectDetected = NO;
    
    cv::vector <cv::KeyPoint> keypointsO; //keypoints for object
    cv::vector <cv::KeyPoint> keypointsS; //keypoints for scene
    
    cv::Mat descriptors_object;
    cv::Mat descriptors_scene;
    cv::SurfFeatureDetector surf(1500);
    surf.detect(sceneMat,keypointsS);
    if(keypointsS.size() < 2) {
        NSLog(@"Object Found");
        return NO;
    }
    surf.detect(objectMat,keypointsO);
    if(keypointsO.size() < 2) {
        NSLog(@"Object Found");
        return NO;
    }
    
    cv::SurfDescriptorExtractor extractor;
    extractor.compute( sceneMat, keypointsS, descriptors_scene );
    extractor.compute( objectMat, keypointsO, descriptors_object );
    
    // brute force search
    cv::BFMatcher matcher(cv::NORM_L1);
    
    std::vector <cv::vector <cv::DMatch>> matches;
    matcher.knnMatch( descriptors_object, descriptors_scene, matches, 2 );
    
    cv::vector <cv::DMatch> good_matches;
    good_matches.reserve(matches.size());
    
    for (size_t i = 0; i < matches.size(); ++i)
    {
        if (matches[i].size() < 2)
            continue;
        
        const cv::DMatch &m1 = matches[i][0];
        const cv::DMatch &m2 = matches[i][1];
        
        float nndrRatio = 0.70f;
        if(m1.distance <= nndrRatio * m2.distance)
            good_matches.push_back(m1);
    }
    
    if( (good_matches.size() >=7)) {
        NSLog(@"Object Found");
            
        std::vector< cv::Point2f > obj;
        std::vector< cv::Point2f > scene;
            
        for( unsigned int i = 0; i < good_matches.size(); i++ ) {
            obj.push_back( keypointsO[ good_matches[i].queryIdx ].pt );
            scene.push_back( keypointsS[ good_matches[i].trainIdx ].pt );
        }
            
        cv::Mat H = findHomography( obj, scene, CV_RANSAC );
            

        std::vector < cv::Point2f > obj_corners(4);
        obj_corners[0] = cvPoint(0,0);
        obj_corners[1] = cvPoint( objectMat.cols, 0 );
        obj_corners[2] = cvPoint( objectMat.cols, objectMat.rows );
        obj_corners[3] = cvPoint( 0, objectMat.rows );
        
        std::vector < cv::Point2f > scene_corners(4);
        
        cv::perspectiveTransform( obj_corners, scene_corners, H);
        
        
        objectDetected = YES;

    } else {
        NSLog(@"OBJECT NOT FOUND!");
    }

    return objectDetected;
    
}



@end
