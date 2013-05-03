//
//  DrewFaceDetectPart2.cpp
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "DrewFaceDetectPart2.h"
#define _USE_MATH_DEFINES
#include <math.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui_c.h>

#define GET_PIXELORIG(X,Y,Z) testimagedataOrig[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXEL(X,Y,Z) testimagedata[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD1(X,Y,Z) testimagedataMod1[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD2(X,Y,Z) testimagedataMod2[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define PIXEL_INDEX(X,Y) Y *(int)mouthImage.size.width + X

#define DELTA_ALLOWED_FOR_WHITE 100
#define THRESHOLD_WHITE_BLACK 10
#define MIN_Y_BRIGHTNESS_THRESHOLD 150
#define MAX_Y_FOR_DARK_THRESHOLD 250
#define MAX_CR_THRESHOLD_WHITETEETH 20
#define MAX_CB_THRESHOLD_WHITETEETH 10
#define EXPECT_TEETH 5
#define NUMBER_OF_LINES 10000
#define MIN_TOOTH_SIZE 20
#define MAX_TOOTH_SIZE 50
#define MIN_DARK_SIZE 1
#define MAX_DARK_SIZE 4
#define NO 0
#define YES 1

const int HOW_MANY_BUCKETS = 50;

struct CalcStruct {
    NotCGPoint pt;
    int diffCr;
};
typedef struct CalcStruct CalcStruct;

typedef struct pindex pointIndex;


char looksWhite(uint8_t toothY, uint8_t toothCr, uint8_t toothCb,uint8_t prevToothY) {
    if (toothY < MIN_Y_BRIGHTNESS_THRESHOLD) {
        return NO;
    }
    
    if (prevToothY != -1 && abs(prevToothY - toothY) > DELTA_ALLOWED_FOR_WHITE) {
        return NO;
    }
    if (toothCr > MAX_CR_THRESHOLD_WHITETEETH) {
        return NO;
    }
    if (toothCb > MAX_CB_THRESHOLD_WHITETEETH) {
        return NO;
    }
    return YES;
}

/**drew's handy dandy translation guide:
 image.size.width == matrix.cols
 image.size.height == matrix.rows
 */

#define GET_PIXEL_OF_MATRIX4(MTX,X,Y,CHANNEL) MTX.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL]
#define SET_PIXEL_OF_MATRIX4(MTX,X,Y,CHANNEL,VALUE) MTX.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL] = VALUE
#define GET_PIXEL_OF_MATRIX3(MTX,X,Y,CHANNEL) MTX.at<cv::Vec<uint8_t,3>>(Y,X)[CHANNEL]
#define SET_PIXEL_OF_MATRIX3(MTX,X,Y,CHANNEL,VALUE) MTX.at<cv::Vec<uint8_t,3>>(Y,X)[CHANNEL] = VALUE

cv::Mat findTeethAreaDebug(cv::Mat image) {
    
    //first we build a custom color space to work in.  This space is given in §L181, and an empirical derivation on §L184.
    cv::Mat RGB = image.clone();
    cv::cvtColor(image, RGB, CV_BGRA2BGR);
    
    cv::Mat CIELAB = RGB.clone();
    cv::cvtColor(image, CIELAB, CV_BGR2Lab);
    
    cv::Mat CIELUV = RGB.clone();
    cv::cvtColor(image, CIELUV, CV_BGR2Luv);
    
    cv::Mat CIELAU = RGB.clone();
    for(int x = 0; x < image.cols; x++) {
        for(int y = 0; y < image.rows; y++) {
            /*
            int k1 = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 0);
            int k2 = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 1);
            int k3 = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 2);
            int k4 = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 0);
            int k5 = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 1);
            int k6 = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 2);*/
            int l = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 0);
            int l2 = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 0);
            assert(fabs(l - l2) < 5);
            int a = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 1);
            int u = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 1);
            SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 0, l);
            SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 1, a);
            SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 2, u);

        }
    }
    
    //now we apply a fairly robust transformation on the luminance.  The transformation is given on §L183.
    for(int x = 0; x < image.cols; x++) {
        for(int y = 0; y < image.rows; y++) {
            int top_l_value = GET_PIXEL_OF_MATRIX3(CIELAU, x, 0, 0);
            int bottom_l_value = GET_PIXEL_OF_MATRIX3(CIELAU, x, image.rows-1, 0);
            float t1 = GET_PIXEL_OF_MATRIX3(CIELAU, x, y, 0);
            float t2 = (bottom_l_value - top_l_value) / (image.rows - 1.0) * (y - 1);
            float t3 = (top_l_value + bottom_l_value) / 2.0;
            float t4 = -1 * bottom_l_value;
            float newLuminance = t1 + t2 + t3 + t4;
            SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 0, newLuminance);
        }
    }
    
    
    //now we partition on the formula given by §L184
    double meanU = 0;
    double meanA = 0;
    for(int x = 0; x < image.cols; x++) {
        int rSumA = 0;
        int rSumU = 0;
        for(int y = 0; y < image.rows; y++) {
            int a = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 1);
            int u = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 1);
            rSumA += a;
            rSumU += u;
        }
        meanA += (rSumA * 1.0 / (image.rows * image.cols));
        meanU += (rSumU * 1.0 / (image.rows * image.cols));
    }
    assert(meanA >= 0);
    assert(meanU >= 0);
    assert(meanA <= 255);
    assert(meanU <= 255);
    double stdevA = 0;
    double stdevU = 0;
    for(int x = 0; x < image.cols; x++) {
        for(int y = 0; y < image.rows; y++) {
            int a = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 1);
            int u = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 1);
            stdevA += powf(a-meanA, 2) / (image.rows * image.cols);
            stdevU += powf(u-meanU, 2) / (image.rows * image.cols);
        }

    }
    stdevA = sqrtf(stdevA);
    stdevU = sqrtf(stdevU);
    assert(stdevA >= 0);
    assert(stdevU >= 0);
    assert(stdevA <= 255);
    assert(stdevU<= 255);
    
    int tA = meanA - stdevA;
    if (tA < 142) tA = 142;
    
    int tU = meanU - stdevU;
    if (tU < 75) tU = 75;
    
    for(int x = 0; x < image.cols; x++) {
        for(int y = 0; y < image.rows; y++) {
            int a = GET_PIXEL_OF_MATRIX3(CIELAB, x, y, 1);
            int u = GET_PIXEL_OF_MATRIX3(CIELUV, x, y, 1);
            int l = GET_PIXEL_OF_MATRIX3(CIELAU, x, y, 0);
            if (a <= tA || u <= tU || l <= 89) {
                SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 0, 0);
                SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 1, 0);
                SET_PIXEL_OF_MATRIX3(CIELAU, x, y, 2, 0);

            }
        }
    }
    
    //we interpret the CIELAU as RGB for unusual display.  The parent implementation wants a RGBA (4-component) output.
    cv::cvtColor(CIELAU, CIELAU, CV_BGR2BGRA);
    return CIELAU;
}


std::vector<NotCGPoint>* findTeethArea(cv::Mat image) {
    //originally: mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //this implementation looks approximately in-place to me
    //cv::blur(myCvMat, edges, cv::Size(4,4));

	printf("finding teeth area\n");
    image = findTeethAreaDebug(image);
    
    return new std::vector<NotCGPoint>;
    
    
}