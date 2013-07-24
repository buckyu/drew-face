//
//  SmileStitcher.cpp
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "SmileStitcher.h"
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2/stitching/detail/exposure_compensate.hpp>
#define _USE_MATH_DEFINES
#include <math.h>
#include <stdint.h> //gets uint8_t
#include <vector>
#include "jpegHelpers.h"
#include "FaceDetectRenamed.h"

#ifdef DONT_PORT
    #define COLOR_CHANNELS 4
#else
    #define COLOR_CHANNELS 4
#endif

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
    sprintf(ret, "%.*s-replaced.jpg", (int)strlen(fileInfo->originalFileNamePath) - 4, fileInfo->originalFileNamePath);

    struct jpeg *face = loadJPEGFromFile(fileInfo->originalFileNamePath, COLOR_CHANNELS);
    //writeJpegToFile(face, ret, 100);
    struct jpeg *mouth = loadJPEGFromFile(mouthImage, COLOR_CHANNELS);

    std::vector<cv::Point> *bounds = new std::vector<cv::Point>;
    int boundArraySize = fileInfo->imagePoints->size();
    cv::Point *boundArray = (cv::Point*)calloc(boundArraySize, sizeof(cv::Point));

    float xsquaredSum = 0;
    float xSum = 0;
    float ySum = 0;
    float xySum = 0;
    int n = fileInfo->imagePoints->size();
    if(n == 0) {
        return NULL;
    }

    int minx = INT_MAX;
    int miny = INT_MAX;
    int maxx = INT_MIN;
    int maxy = INT_MIN;
    //FILE *file = fopen("/Users/bion/Desktop/data.csv", "w");
    //int lastx = fileInfo->points->at(0).x;
    for(int i = 0; i < n; i++) {
        NotCGPoint p = fileInfo->imagePoints->at(i);
        //fprintf(file, "%d, %d\n", p.x, p.y);
        if(p.x < minx) {
            minx = p.x;
        }
        if(p.x > maxx) {
            maxx = p.x;
        }
        if(p.y < miny) {
            miny = p.y;
        }
        if(p.y > maxy) {
            maxy = p.y;
        }
        cv::Point pt = cv::Point(p.x, p.y);
        //printf("Point = (%d, %d)\n", p.x, p.y);
        bounds->push_back(pt);
        boundArray[i] = pt;

        xsquaredSum += p.x * p.x;
        xSum += p.x;
        ySum += p.y;
        xySum += p.x * p.y;
    }

    ///http://math.stackexchange.com/questions/267865/equations-for-quadratic-regression
    float n2 = fileInfo->bottomLip->size();
    if(n == 0) {
        return NULL;
    }
    float x2Sum = 0;
    float x1Sum = 0;
    float x1x2Sum = 0;
    float x2SquaredSum = 0;
    float x1y1Sum = 0;
    float y1Sum = 0;
    float x2y1Sum = 0;
    float x1SquaredSum = 0;
    for(int i = 0; i < n2; i++) {
        NotCGPoint p = fileInfo->bottomLip->at(i);
        float x1 = p.x;
        float x2 = p.x * p.x;
        x2Sum += x2;
        x1Sum += x1;
        x1x2Sum += x1 * x2;
        x2SquaredSum += x2 * x2;
        x1y1Sum += x1 * p.y;
        y1Sum += p.y;
        x2y1Sum += x2 * p.y;
        x1SquaredSum += x1 * x1;
    }

    float s11 = x1SquaredSum - x1Sum * x1Sum / n2;
    float s12 = x1x2Sum - x1Sum * x2Sum / n2;
    float s22 = x2SquaredSum - x2Sum * x2Sum / n2;
    float sy1 = x1y1Sum - y1Sum * x1Sum / n2;
    float sy2 = x2y1Sum - y1Sum * x2Sum / n2;
    float x1Bar = x1Sum / n2;
    float x2Bar = x2Sum / n2;
    float y1Bar = y1Sum / n2;
    float beta2 = (sy1 * s22 - sy2 * s12) / (s22 * s11 - s12 * s12);
    float beta3 = (sy2 * s11 - sy1 * s12) / (s22 * s11 - s12 * s12);
    float beta1 = y1Bar - beta2 * x1Bar - beta3 * x2Bar;
    //y = beta1 + beta2 * x + beta3 * xsquared

    //fclose(file);
#define STOCK_IMAGE_TOOTH_WIDTH 25
    //Drew wants to resize width based on matching front tooth widths, and resize height proportionally wrt to the *original* mouth image scale (not any scale based on mouthSize)
    //srand(10);
    //fileInfo->frontToothWidth = rand() % 30 + 20;
    fileInfo->frontToothWidth = 32.2;
    assert(fileInfo->frontToothWidth > 0);
    cv::Size mouthSize = cv::Size(maxx - minx, maxy - miny);
    float tempWidth = fileInfo->frontToothWidth / STOCK_IMAGE_TOOTH_WIDTH * mouth->width;
    cv::Size toothScaledMouthSize = cv::Size(tempWidth, tempWidth / mouth->width * mouth->height);
    cv::Rect mouthRect = cv::Rect(minx + (mouthSize.width - toothScaledMouthSize.width) / 2, miny + (mouthSize.height - toothScaledMouthSize.height) / 2, toothScaledMouthSize.width, toothScaledMouthSize.height);
    if(toothScaledMouthSize.width == 0) { //seems to crash in this case.  i assume because the geometry is rediculous
        return NULL;
    }
#undef STOCK_IMAGE_TOOTH_WIDTH

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
    cv::resize(mouthMat, smallMouthMat, toothScaledMouthSize);

#ifdef DONT_PORT
    cv::circle(smallMouthMat, cvPoint(fileInfo->bottomLip->at(0).x, fileInfo->bottomLip->at(0).y), 1, CV_RGB(0, 0, 255), -1);
    for(int i = 1; i < n2; i++) {
        NotCGPoint p1 = fileInfo->bottomLip->at(i - 1);
        NotCGPoint p2 = fileInfo->bottomLip->at(i);
        float y1 = beta1 + beta2 * p1.x + beta3 * p1.x * p1.x;
        float y2 = beta1 + beta2 * p2.x + beta3 * p2.x * p2.x;
        cv::line(smallMouthMat, cvPoint(p1.x, y1), cvPoint(p2.x, y2), CV_RGB(255, 0, 0), 4);
        cv::circle(smallMouthMat, cvPoint(p2.x, p2.y), 1, CV_RGB(0, 0, 255), -1);
    }
#endif

    //printf("img = %s\n", fileInfo->originalFileNamePath);
    //not sure why we have to invert it...
    cv::Mat *rotatedSmallMouthMat = rotateImage(smallMouthMat, -rotation);

    //skew correction
    cv::Mat warpedRotatedSmallMouthMat = *rotatedSmallMouthMat;
    //See also http://opencv.willowgarage.com/wiki/Welcome?action=AttachFile&do=get&target=opencv_cheatsheet.pdf
    //map image onto a sphere and rotate the sphere "up" to flatten out the curvature. Make sure "up" is orthogonal to the center teeth meeting line (ie accounts for the previous rotation)
    ///http://rosettacode.org/wiki/Map_range

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
    cv::Mat smallMouthMask = cvCreateMat(warpedRotatedSmallMouthMat.rows, warpedRotatedSmallMouthMat.cols, CV_8UC1);
    smallMouthMask.setTo(255);

    cv::detail::ExposureCompensator *compensator = new cv::detail::GainCompensator; //bypassing recommended constructor because it has memory issues. Stupid C++
    std::vector<cv::Point> *corners = new std::vector<cv::Point>;
    corners->push_back(cv::Point(0, 0));
    corners->push_back(cv::Point(mouthRect.x, mouthRect.y)); //based on GainCompensator's use of overlapRoi and overlapRoi's definition in modules/stitching/util.cpp:100
    std::vector<cv::Mat> *images = new std::vector<cv::Mat>;
    images->push_back(faceMat);
    images->push_back(warpedRotatedSmallMouthMat);
    std::vector<std::pair<cv::Mat, uchar>> *masks = new std::vector<std::pair<cv::Mat, uchar>>;
    masks->push_back(std::make_pair(mask, 255));
    masks->push_back(std::make_pair(smallMouthMask, 255));
    assert(corners->size() == images->size() && images->size() == masks->size());

    compensator->feed(*corners, *images, *masks);
    compensator->apply(1, corners->at(1), images->at(1), masks->at(1).first);
    IplImage smallMouthImg = warpedRotatedSmallMouthMat;

    //@see jpegHelpers.ccp
    //replace the mask region on face with mouth
    IplImage faceImg = faceMat;
    uint8_t *data = (uint8_t*) faceImg.imageData;
    printf("Using %d color channels\n", COLOR_CHANNELS);
	assert(COLOR_CHANNELS == faceImg.nChannels && COLOR_CHANNELS == smallMouthImg.nChannels);
    for(int y = 0; y < faceImg.height; ++y) {
        uint8_t *maskRow = (uint8_t*)&maskImg.imageData[y * maskImg.width * maskImg.nChannels];
        uint8_t *dataRow = &data[y * faceImg.width * faceImg.nChannels];
        for(int x = 0; x < faceImg.width; ++x) {
            if(maskRow[x * maskImg.nChannels]) {
                if(x >= mouthRect.x && y >= mouthRect.y && x < mouthRect.x + mouthRect.width && y < mouthRect.y + mouthRect.height) {
                    int smallMouthX = x - mouthRect.x;
                    int smallMouthY = y - mouthRect.y;
                    if(smallMouthY >= smallMouthImg.height || smallMouthX >= smallMouthImg.width) {
                        continue; //not sure why the mask didn't work for us. Probably an off-by-one issue. fillPoly drew a border or something.
                    }
                    uint8_t *smallMouthRow = (uint8_t*)&smallMouthImg.imageData[smallMouthY * smallMouthImg.width * smallMouthImg.nChannels];
                    dataRow[x * faceImg.nChannels + 0] = smallMouthRow[smallMouthX * smallMouthImg.nChannels + 0];
                    dataRow[x * faceImg.nChannels + 1] = smallMouthRow[smallMouthX * smallMouthImg.nChannels + 1];
                    dataRow[x * faceImg.nChannels + 2] = smallMouthRow[smallMouthX * smallMouthImg.nChannels + 2];
                } else {
                    dataRow[x * faceImg.nChannels + 0] = 0;
                    dataRow[x * faceImg.nChannels + 1] = 0;
                    dataRow[x * faceImg.nChannels + 2] = 0;
                }
            }
        }
    }

#ifdef DONT_PORT
    cv::Mat outMatrix = &faceImg;
    writeReplaceToDisk(outMatrix, ret);
#else
    face->data = &faceImg;
    face->width = faceImg.width;
    face->height = faceImg.height;
    writeJpegToFile(face, ret, 100);
#endif

    //Short version: free these last. Seriously!
    //Long version: = is overloaded for converting IplImage* <-> cv::Mat. IplImage is a C structure, so when you free it, it actually goes away. cv::Mat is a C++ structure and does some kind of magical reference counting that makes it go away (magically) when you don't need it anymore. So, if you set mat = img and free the img, the img is no longer valid, *BUT* the mat still is. That's right, = has lost the transitive property because of memory management differences within C++. Oh, but some of the data is shared, so although your struct is intact, accessing it can be bad (EXC_BAD_ACCESS bad). Ha ha!
    free(boundArray);
    freeJpeg(mouth);

    return ret;
}