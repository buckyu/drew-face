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

    float xsquaredSum = 0;
    float xSum = 0;
    float ySum = 0;
    float xySum = 0;
    int n = fileInfo->points->size();
    if(n == 0) {
        return NULL;
    }

    int minx = INT_MAX;
    int miny = INT_MAX;
    int maxx = INT_MIN;
    int maxy = INT_MIN;
#define X_STEP 10
    //FILE *file = fopen("/Users/bion/Desktop/data.csv", "w");
    //int lastx = fileInfo->points->at(0).x;
    for(int i = 0; i < n; i++) {
        NotCGPoint p = fileInfo->points->at(i);
        //fprintf(file, "%d, %d\n", p.x, p.y);
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

        xsquaredSum += x*x;
        xSum += x;
        ySum += y;
        xySum += x * y;
    }
    //fclose(file);
#undef X_STEP
    cv::Size mouthSize = cv::Size(maxx - minx, maxy - miny);
    cv::Rect mouthRect = cv::Rect(minx, miny, mouthSize.width, mouthSize.height);

    //use a least squares regression on all the points to get a linear fit that will allow us to approximate the rotation of the overall polygon from horizontal.

    //a * xsquaredSum + b * xSum = xySum
    //a * xSum + b * n = ySum
    cv::Mat_<float> equations1(2, 2);
    equations1[0][0] = xsquaredSum;
    equations1[0][1] = xSum;
    equations1[1][0] = xSum;
    equations1[1][1] = n;

    cv::Mat_<float> equations2(2, 1);
    equations2[0][0] = xySum;
    equations2[0][1] = ySum;
    cv::Mat_<float> solution;
    cv::solve(equations1, equations2, solution);
    float a = solution[0][0];
    //float b = solution[0][1];
    float rotation = atanf(a);

    cv::Mat faceMat = face->data;
    cv::Mat mouthMat = mouth->data;
    cv::Mat smallMouthMat;
    cv::resize(mouthMat, smallMouthMat, mouthSize);
    //printf("img = %s\n", fileInfo->originalFileNamePath);
    //not sure why we have to invert it...
    cv::Mat *rotatedSmallMouthMat = rotateImage(smallMouthMat, -rotation);

    //http://stackoverflow.com/questions/10176184/with-opencv-try-to-extract-a-region-of-a-picture-described-by-arrayofarrays
    //http://www.pieter-jan.com/node/5
    //create a mask and black it out
    cv::Mat mask = cvCreateMat(faceMat.rows, faceMat.cols, CV_8UC1);
    mask.setTo(0);

    //white out the mask region we're actually interested in
    const cv::Scalar white = CV_RGB(255, 255, 255);
    //void fillPoly(Mat& img, const Point** pts, const int* npts, int ncontours, const Scalar& color, int lineType=8, int shift=0, Point offset=Point() );
    cv::fillPoly(mask, (const cv::Point**)&boundArray, &boundArraySize, 1, white);
    IplImage maskImg = mask;

    //balance image exposure
    //http://stackoverflow.com/questions/13978689/balancing-contrast-and-brightness-between-stitched-images
    //http://docs.opencv.org/modules/stitching/doc/exposure_compensation.html
    cv::Mat smallMouthMask = cvCreateMat(rotatedSmallMouthMat->rows, rotatedSmallMouthMat->cols, CV_8UC1);
    smallMouthMask.setTo(255);

    cv::detail::ExposureCompensator *compensator = new cv::detail::GainCompensator; //bypassing recommended constructor because it has memory issues. Stupid C++
    std::vector<cv::Point> *corners = new std::vector<cv::Point>;
    corners->push_back(cv::Point(0, 0));
    corners->push_back(cv::Point(mouthRect.x, mouthRect.y)); //based on GainCompensator's use of overlapRoi and overlapRoi's definition in modules/stitching/util.cpp:100
    std::vector<cv::Mat> *images = new std::vector<cv::Mat>;
    images->push_back(faceMat);
    images->push_back(*rotatedSmallMouthMat);
    std::vector<std::pair<cv::Mat, uchar>> *masks = new std::vector<std::pair<cv::Mat, uchar>>;
    masks->push_back(std::make_pair(mask, 255));
    masks->push_back(std::make_pair(smallMouthMask, 255));
    assert(corners->size() == images->size() && images->size() == masks->size());

    compensator->feed(*corners, *images, *masks);
    compensator->apply(1, corners->at(1), images->at(1), masks->at(1).first);
    IplImage smallMouthImg = *rotatedSmallMouthMat;

    //@see jpegHelpers.ccp
    //replace the mask region on face with mouth
    IplImage faceImg = faceMat;
    uint8_t *data = (uint8_t*) faceImg.imageData;
    for(int y = 0; y < faceImg.height; ++y) {
        for(int x = 0; x < faceImg.width; ++x) {
            if(maskImg.imageData[y * maskImg.widthStep + x * maskImg.nChannels]) {
                int smallMouthX = x - mouthRect.x;
                int smallMouthY = y - mouthRect.y;
                if(smallMouthY >= smallMouthImg.height || smallMouthX >= smallMouthImg.width) {
                    continue; //not sure why the mask didn't work for us. Probably and off-by-one issue. fillPoly drew a border or something.
                }
                data[y * faceImg.widthStep + x * faceImg.nChannels + 0] = smallMouthImg.imageData[smallMouthY * smallMouthImg.widthStep + smallMouthX * smallMouthImg.nChannels + 0];
                data[y * faceImg.widthStep + x * faceImg.nChannels + 1] = smallMouthImg.imageData[smallMouthY * smallMouthImg.widthStep + smallMouthX * smallMouthImg.nChannels + 1];
                data[y * faceImg.widthStep + x * faceImg.nChannels + 2] = smallMouthImg.imageData[smallMouthY * smallMouthImg.widthStep + smallMouthX * smallMouthImg.nChannels + 2];
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