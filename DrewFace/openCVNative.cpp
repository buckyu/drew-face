//
//  openCVNative.cpp
//  DrewFace
//
//  Created by Drew Crawford on 4/5/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "openCVNative.h"
#include "Detect.h"
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2/imgproc/imgproc.hpp>

rect opencvFaceDetect(IplImage *myImage, const char*fn)  {
    // Load XML
    
    rect myRect;
    Detect(myImage, fn, &myRect, "Face", fn);
    return myRect;
}

/**fn here is a path to haarcascade_frontalface_default.xml */
cv::Mat *processUIImageForFace(cv::Mat *img, const char *fn, rect *outRect) {
    
    cv::Mat myCvMat = *img;
    cv::Mat greyMat;
    cv::cvtColor(myCvMat, greyMat, CV_BGR2GRAY);
    
    // face detection
    IplImage myImage = myCvMat;
    rect faceDetectedInRect = opencvFaceDetect(&myImage, fn);
    *outRect = faceDetectedInRect;
    
    //return [self UIImageFromCVMat:greyMat];
    return img;
}

rect processUIImageForMouth(cv::Mat *img, const char *haarcascade_mcs_mouth_path)  {
    // Load XML
    rect myRect;
    IplImage myImage = *img;
    Detect(&myImage, haarcascade_mcs_mouth_path, &myRect, "Mouth", "Unknown image (information lost due to refactor)");
    return myRect;
}

cv::Mat edgeDetectReturnOverlay(cv::Mat *img) {
    cv::Mat myCvMat = *img;
    cv::Mat edges;
    cv::cvtColor(myCvMat, edges, CV_BGR2GRAY);
    cv::Canny(edges, edges, 30, 255);
    cv::cvtColor(edges, edges, CV_GRAY2BGRA);
    myCvMat = myCvMat - edges;
    
    return myCvMat;
}

