#include "OpenCVClass.h"
#include "Detect.h"
#include <opencv2\imgproc\imgproc_c.h>
#include <opencv2\imgproc\imgproc.hpp>
#include <opencv2\features2d\features2d.hpp>
#include <opencv2\nonfree\features2d.hpp>

rect opencvFaceDetect(IplImage *myImage, const char *fn);
rect opencvMouthDetect(IplImage *myImage, const char *fn);

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


cv::Rect processUIImageForMouth(cv::Mat *colorimg, const char *fn) {
    
    cv::Mat myCvMat = *colorimg;
    
    // mouth detection
    IplImage myImage = myCvMat;
    rect mouthDetectedInRect = opencvMouthDetect(&myImage, fn);
    
    return cvRect(mouthDetectedInRect.x, mouthDetectedInRect.y, mouthDetectedInRect.width, mouthDetectedInRect.height);
}


rect opencvFaceDetect(IplImage *myImage, const char *fn)  {
    // Load XML
    const char *path = "haarcascade_frontalface_default.xml";
    rect myRect;
    Detect(myImage, path, &myRect, "Face", fn);
    return myRect;
}


rect opencvMouthDetect(IplImage *myImage, const char *fn)  {
    // Load XML
    const char *path = "haarcascade_mcs_mouth.xml";
    rect myRect;
    Detect(myImage, path, &myRect, "Mouth", fn);
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