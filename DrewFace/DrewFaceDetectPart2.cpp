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

cv::Mat findTeethAreaDebug(cv::Mat image) {
    cv::cvtColor(image, image, CV_BGRA2BGR);
    cv::pyrMeanShiftFiltering(image.clone(), image, 20, 20, 4);
    cv::cvtColor(image, image, CV_BGR2BGRA);
    return image;
}


std::vector<NotCGPoint>* findTeethArea(cv::Mat image) {
    //originally: mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //this implementation looks approximately in-place to me
    //cv::blur(myCvMat, edges, cv::Size(4,4));
	printf("finding teeth area\n");
    image = findTeethAreaDebug(image);
    
    assert(image.dims==2);
    assert(CV_MAT_TYPE(image.type())==CV_8UC4);
    
    
    
    /**drew's handy dandy translation guide:
     image.size.width == matrix.cols
     image.size.height == matrix.rows
     */
    printf("%d\n",sizeof(ushort));
    //if you want to grab x: 5, y: 12, channel: g, you do this one:
#define GET_PIXEL_OF_MATRIX(MTX,X,Y,CHANNEL) image.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL]
#define WIDTH image.cols
#define HEIGHT image.rows

    
    uint8_t *testimagedataMod1 = (uint8_t*)malloc(HEIGHT * WIDTH *4);
    uint8_t *testimagedataMod2 = (uint8_t*)malloc(HEIGHT * WIDTH *4);
    memset(testimagedataMod1, 0,HEIGHT * WIDTH *4);
    memset(testimagedataMod2, 0,HEIGHT * WIDTH *4);


    for(int x = 0; x < WIDTH; x++) {
        for(int y = 0; y < HEIGHT; y++) {
            
            uint8_t pxR = GET_PIXEL_OF_MATRIX(image, x, y, 0);
            uint8_t pxG = GET_PIXEL_OF_MATRIX(image, x, y, 1);
            uint8_t pxB = GET_PIXEL_OF_MATRIX(image, x, y, 2);
            float Y = 0.299*(float)pxR + 0.587*(float)pxG + 0.114*(float)pxB;
            float CR = 0.713*((float)pxR - Y);
            if (CR<0) CR = 0;
            if (CR>255) CR = 255;
            float CB = 0.564*((float)pxB - Y);
            if (CB<0) CB= 0;
            if (CB>255) CB = 255;
            
            GET_PIXELMOD1(x,y,0) = Y;
            GET_PIXELMOD1(x,y,1) = CR;
            GET_PIXELMOD1(x,y,2) = CB;
        }
    }
    
    int MouthWidth = WIDTH;
    int MouthHeight = HEIGHT;
    int cX = MouthWidth / 2;
    int cY = MouthHeight / 2;

    int baseY = GET_PIXELMOD1(cX, cY, 0);
    int baseCr = GET_PIXELMOD1(cX, cY, 1);
    int baseCb = GET_PIXELMOD1(cX, cY, 2);
    printf("hi!");
#define COLOR_THRESHOLD 15
#define SLICE_FOR_NUM_SLICES(num) (M_PI_4 / (num / 8))
#define POINTS_PER_VECTOR 8
    std::vector<NotCGPoint> *solutionArray = new std::vector<NotCGPoint>;
    std::vector<std::vector<NotCGPoint>*> *vectors = new std::vector<std::vector<NotCGPoint>*>;
    for(float theta = 0; theta <= 2 * M_PI; theta += SLICE_FOR_NUM_SLICES(1024)) {
        std::vector<NotCGPoint> *transitions = new std::vector<NotCGPoint>;
        int transitionCount = 0;
        for(float r = 0; r <= MouthWidth / 2; r += 0.5) {
            int x = (int)roundf(cX + r * cos(theta));
            int y = (int)roundf(cY + r * sin(theta));
            if(x < 0 || y < 0 || x >= MouthWidth || y >= MouthHeight) {
                break;
            }

            int testY = GET_PIXELMOD1(x, y, 0);
            int testCr = GET_PIXELMOD1(x, y, 1);
            int testCb = GET_PIXELMOD1(x, y, 2);

            int diffY = abs(testY - baseY);
            int diffCr = abs(testCr - baseCr);
            int diffCb = abs(testCb - baseCb);

            if(diffCr > COLOR_THRESHOLD) {
                //GET_PIXELMOD2(x, y, 0) = 0xff;
                NotCGPoint pt;
                pt.x = x;
                pt.y = y;
                transitions->push_back(pt);
                transitionCount++;
                if(++transitionCount == POINTS_PER_VECTOR) {
                    solutionArray->push_back(pt);
                    break;
                }
                baseY = testY;
                baseCr = testCr;
                baseCb = testCb;
            }
        }
        vectors->push_back(transitions);
    }

    free(testimagedataMod1);
    free(testimagedataMod2);
    
    printf("solution of size %lu\n",solutionArray->size());

    return solutionArray;
    
}