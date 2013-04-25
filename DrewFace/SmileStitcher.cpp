//
//  SmileStitcher.cpp
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "SmileStitcher.h"
#include <opencv2/highgui/highgui_c.h>
#include "jpegHelpers.h"
#include "FaceDetectRenamed.h"

#define COLOR_CHANNELS 4

#ifdef DONT_PORT
#include "FaceDetectRenamedObjCExtensions.h"
#endif

//http://stackoverflow.com/questions/14063070/overlay-a-smaller-image-on-a-larger-image-python-opencv

//**********************************************
//SERIOUSLY: jpegs do NOT have alpha channels!!!
//**********************************************
const char *stitchMouthOnFace(FileInfo *fileInfo, const char *mouthImage) {
    char *ret = (char*)calloc(strlen(fileInfo->originalFileNamePath) + 9 + 1, sizeof(char));
    if(!ret) {
        //out of memory
        return NULL;
    }
    sprintf(ret, "%s-replaced", fileInfo->originalFileNamePath);

    struct jpeg *face = loadJPEGFromFile(fileInfo->originalFileNamePath, COLOR_CHANNELS);
    struct jpeg *mouth = loadJPEGFromFile(mouthImage, COLOR_CHANNELS);

    std::vector<cv::Point> *bounds = new std::vector<cv::Point>;
    int boundArraySize = fileInfo->points->size();
    cv::Point *boundArray = (cv::Point*)calloc(boundArraySize, sizeof(cv::Point));
    //this is THE screwiest coordinate conversion I have ever seen. I shall refrain from ranting. But you, dear reader, should feel free.
    cv::Point facePoint = cv::Point(fileInfo->facedetectX / fileInfo->facedetectScaleFactor, fileInfo->facedetectY / fileInfo->facedetectScaleFactor);
    cv::Point mouthPoint = cv::Point(facePoint.x + fileInfo->mouthdetectX / fileInfo->facedetectScaleFactor, facePoint.y + fileInfo->mouthdetectY / fileInfo->facedetectScaleFactor + MAGIC_HEIGHT * fileInfo->facedetectH / fileInfo->facedetectScaleFactor);
    int minx = INT_MAX;
    int miny = INT_MAX;
    int maxx = INT_MIN;
    int maxy = INT_MIN;
    for(int i = 0; i < fileInfo->points->size(); i++) {
        NotCGPoint p = fileInfo->points->at(i);
        int x = mouthPoint.x + p.x / fileInfo->facedetectScaleFactor;
        if(x < minx) {
            minx = x;
        }
        if(x > maxx) {
            maxx = x;
        }
        int y = mouthPoint.y + p.y / fileInfo->facedetectScaleFactor;
        if(y < miny) {
            miny = y;
        }
        if(y > maxy) {
            maxy = y;
        }
        cv::Point pt = cv::Point(x, y);
        //printf("Point = (%d, %d)\n", p.x, p.y);
        bounds->push_back(pt);
        boundArray[i] = pt;
    }
    cv::Size mouthSize = cv::Size(maxx - minx, maxy - miny);
    cv::Rect mouthRect = cv::Rect(minx, miny, mouthSize.width, mouthSize.height);

    cv::Mat faceMat = face->data;
    cv::Mat mouthMat = mouth->data;
    cv::Mat smallMouthMat;
    cv::resize(mouthMat, smallMouthMat, mouthSize);
    IplImage smallMouthImg = smallMouthMat;

    //http://stackoverflow.com/questions/10176184/with-opencv-try-to-extract-a-region-of-a-picture-described-by-arrayofarrays
    //http://www.pieter-jan.com/node/5
    //create a mask and black it out
    cv::Mat mask = cvCreateMat(faceMat.rows, faceMat.cols, CV_8UC1);
    for(int i = 0; i < mask.cols; i++) {
        for(int j = 0; j < mask.rows; j++) {
            mask.at<uchar>(cv::Point(i, j)) = 0;
        }
    }

    //white out the mask region we're actually interested in
    const cv::Scalar white = CV_RGB(255, 255, 255);
    //void fillPoly(Mat& img, const Point** pts, const int* npts, int ncontours, const Scalar& color, int lineType=8, int shift=0, Point offset=Point() );
    cv::fillPoly(mask, (const cv::Point**)&boundArray, &boundArraySize, 1, white);
    IplImage maskImg = mask;

    //replace the mask region on face with mouth
    IplImage faceImg = faceMat;
    for(int y = 0; y < faceImg.height; ++y) {
        for(int x = 0; x < faceImg.width; ++x) {
            uint8_t *data = (uint8_t*) faceImg.imageData;

            if(maskImg.imageData[y * maskImg.widthStep + x * maskImg.nChannels]) {
                data[y * faceImg.widthStep + x * faceImg.nChannels + 0] = smallMouthImg.imageData[(y - mouthRect.y) * smallMouthImg.widthStep + (x - mouthRect.x) * smallMouthImg.nChannels + 0];
                data[y * faceImg.widthStep + x * faceImg.nChannels + 1] = smallMouthImg.imageData[(y - mouthRect.y) * smallMouthImg.widthStep + (x - mouthRect.x) * smallMouthImg.nChannels + 1];
                data[y * faceImg.widthStep + x * faceImg.nChannels + 2] = smallMouthImg.imageData[(y - mouthRect.y) * smallMouthImg.widthStep + (x - mouthRect.x) * smallMouthImg.nChannels + 2];
            }
        }
    }

    cv::Mat outMatrix = &faceImg;
#if DONT_PORT
    writeReplaceToDisk(outMatrix, ret);
#endif

    //Short version: free these last. Seriously!
    //Long version: = is overloaded for converting IplImage* <-> cv::Mat. IplImage is a C structure, so when you free it, it actually goes away. cv::Mat is a C++ structure and does some kind of magical reference counting that makes it go away (magically) when you don't need it anymore. So, if you set mat = img and free the img, the img is no longer valid, *BUT* the mat still is. That's right, = has lost the transitive property because of memory management differences within C++. Oh, but some of the data is shared, so although your struct is intact, accessing it can be bad (EXC_BAD_ACCESS bad). Ha ha!
    free(boundArray);
    freeJpeg(face);
    freeJpeg(mouth);

    return ret;
}