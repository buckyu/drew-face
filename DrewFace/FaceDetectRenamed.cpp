//
//  FaceDetectRenamed.cpp
//  DrewFace
//
//  Created by Drew Crawford on 4/5/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "FaceDetectRenamed.h"
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <stdio.h>
#include "DrewFaceDetectPart2.h"
#include "openCVNative.h"
#define _USE_MATH_DEFINES
#include <math.h>
#include <time.h>
#include "jpegHelpers.h"

#ifdef __APPLE__
#define DONT_PORT 1
#endif
#ifdef DONT_PORT
#import "FaceDetectRenamedObjCExtensions.h"

#endif

/**haar_cascade_path here is a path to haarcascade_frontalface_default.xml */
FileInfo *extractGeometry(const char *fileNamePath, const char* face_haar_cascade_path,const char *mouth_haar_casecade_path) {
    printf("processing image %s",fileNamePath);

	//timebomb
	//
	time_t now = time(NULL);
	time_t timebomb = 1372655105; //7/1/2013
	if (timebomb < now) {
			printf("The active render target and depth stencil surface must have the same pixel size and multisampling type.\n");
			return NULL;
	}


    // Find Mouths in original images here
    
    struct jpeg *jpeg = loadJPEGFromFile(fileNamePath, 4);
    if(jpeg == NULL) {
        return NULL;
    }
    float facedetectScaleFactor = 1;
    cv::Mat scaledImg;
    {
        int w = jpeg->width;
        int h = jpeg->height;
        int max = (w > h)? w : h;
        if( max > 1024) {
            //facedetectScaleFactor = maxDimension / (float)max;
            cv::Mat mat = jpeg->data;
            facedetectScaleFactor = 1024.0 / max;
            cv::resize(mat, scaledImg, cv::Size(w * facedetectScaleFactor, h * facedetectScaleFactor), 0, 0);
        } else {
            scaledImg = jpeg->data;
        }
    }
    printf("about to exif\n");
    int orientation = exifOrientation(fileNamePath);
	printf("exif complete\n");
    cv::Mat *rotatedImage = &scaledImg;
    
    // Orient images for face detection (EXIF Orientation = 0)
    if (orientation == 6) {
        rotatedImage = rotateImage(scaledImg, -M_PI_2);
    } else if (orientation == 3) {
        rotatedImage = rotateImage(scaledImg, M_PI_2);
    } else if (orientation > 1) {
        printf("%s Orientation %d not 0, 1 or 6. Need to accommodate here", fileNamePath, orientation);
    }
    
    // search for face in scaledImage
    // OpenCV Processing Called Here for Face Detect
    
    // testimage - faceRectInScaledOrigImage is set by delegate method call
    //OpenCvClass *ocv = [OpenCvClass new];
    rect faceRect;
    
    
    printf("begin opencv\n");
	cv::Mat *testimage = processUIImageForFace(rotatedImage, face_haar_cascade_path, &faceRect); //[ocv processUIImageForFace:rotatedImage fromFile:fileNamePath outRect:&faceRect];
    
    if ((faceRect.width == 0) || (faceRect.height == 0)) {
        printf("NO FACE in %s\n", fileNamePath);
        return NULL;
    }
    
    // extract bottom half of face from COLOR image
    // locate mouth in bottom half of greyscale face image
    IplImage testImageImage = *testimage;
    cv::Rect roi = cvRect((int)(faceRect.x), (int)(faceRect.y+MAGIC_HEIGHT*faceRect.height), (int)(faceRect.width), (int)(0.34*faceRect.height));
    cvSetImageROI(&testImageImage, roi);
    IplImage *cropImage = cvCreateImage(cvGetSize(&testImageImage), testImageImage.depth, testImageImage.nChannels);
    cvCopy(&testImageImage, cropImage);
    cvResetImageROI(&testImageImage);
    cv::Mat bottomhalffaceImage = cropImage;
    //NSData *testData = UIImageJPEGRepresentation([OpenCvClass UIImageFromCVMat:bottomhalffaceImage], 0.8);
    
    // do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
    // bottomhalffaceImage = [ocv greyTheImage:bottomhalffaceImage];
    
    //int mouthIdx = -1;
    rect mouthRectInBottomHalfOfFace;
    mouthRectInBottomHalfOfFace.x = 0; mouthRectInBottomHalfOfFace.y = 0; mouthRectInBottomHalfOfFace.width = 0; mouthRectInBottomHalfOfFace.height = 0;
    
    // OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
	mouthRectInBottomHalfOfFace = processUIImageForMouth(&bottomhalffaceImage, mouth_haar_casecade_path); //mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:&bottomhalffaceImage fromFile:fileNamePath];
    
    // BruteForce Processing Called Here - search for mouth in bottom half of greyscale face
    // using MODELMOUTHxxx.png files in /MODEL_MOUTHS/
    //[self processUIImageForMouth:bottomhalffaceImage returnRect:&mouthRectInBottomHalfOfFace closestMouthMatch:&mouthIdx fileName:fileName];
    
    if ((mouthRectInBottomHalfOfFace.width == 0) || (mouthRectInBottomHalfOfFace.height == 0)) {
        printf("NO MOUTH in %s\n", fileNamePath);
        return NULL;
    }
    
    // extract mouth from face
    testImageImage = bottomhalffaceImage;
    roi = cvRect(mouthRectInBottomHalfOfFace.x, mouthRectInBottomHalfOfFace.y, mouthRectInBottomHalfOfFace.width, mouthRectInBottomHalfOfFace.height);
    cvSetImageROI(&testImageImage, roi);
    cropImage = cvCreateImage(cvGetSize(&testImageImage), testImageImage.depth, testImageImage.nChannels);
    cvCopy(&testImageImage, cropImage);
    cvResetImageROI(&testImageImage);
    cv::Mat mouthImage = cropImage;
    
    cv::Mat processedMouthImage;
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
        processedMouthImage = mouthImage;
        //processedMouthImage =  edgeDetectReturnOverlay(&mouthImage); //[ocv edgeDetectReturnOverlay:&mouthImage];

    }
    
    
    // write mouth images to EXTRACTED_MOUTHS directory
#if DONT_PORT
    writeToDisk(mouthImage,fileNamePath);
#endif
    
    //processedMouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    FileInfo *ret = (FileInfo*)malloc(sizeof(FileInfo));
    ret->originalFileNamePath = fileNamePath;
    ret->facedetectScaleFactor = facedetectScaleFactor;
    ret->facedetectX = faceRect.x;
    ret->facedetectY = faceRect.y;
    ret->facedetectW = faceRect.width;
    ret->facedetectH = faceRect.height;
    ret->mouthdetectX = mouthRectInBottomHalfOfFace.x;
    ret->mouthdetectY = mouthRectInBottomHalfOfFace.y;
    ret->mouthdetectW = mouthRectInBottomHalfOfFace.width;
    ret->mouthdetectH = mouthRectInBottomHalfOfFace.height;
    
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
        ret->points = findTeethArea(mouthImage);

        std::vector<NotCGPoint> *imagePoints = new std::vector<NotCGPoint>;
        //this is THE screwiest coordinate conversion I have ever seen. I shall refrain from ranting. But you, dear reader, should feel free.
        cv::Point facePoint = cv::Point(ret->facedetectX / ret->facedetectScaleFactor, ret->facedetectY / ret->facedetectScaleFactor);
        cv::Point mouthPoint = cv::Point(facePoint.x + ret->mouthdetectX / ret->facedetectScaleFactor, facePoint.y + ret->mouthdetectY / ret->facedetectScaleFactor + MAGIC_HEIGHT * ret->facedetectH / ret->facedetectScaleFactor);
        for(int i = 0; i < ret->points->size(); i++) {
            NotCGPoint pt = ret->points->at(i);
            NotCGPoint p;
            p.x = mouthPoint.x + pt.x / ret->facedetectScaleFactor;
            p.y = mouthPoint.y + pt.y / ret->facedetectScaleFactor;
            imagePoints->push_back(p);
        }
        ret->imagePoints = imagePoints;
    }
    
    return ret;
}