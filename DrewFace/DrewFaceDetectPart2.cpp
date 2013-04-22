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
    cv::pyrMeanShiftFiltering(image.clone(), image, 30, 30, 4);
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
#define COLOR_THRESHOLD 20
#define SLICE_FOR_NUM_SLICES(num) (M_PI_4 / (num / 8))
    std::vector<NotCGPoint> *solutionArray = new std::vector<NotCGPoint>;
    for(float theta = 0; theta <= 2 * M_PI; theta += SLICE_FOR_NUM_SLICES(1024)) {
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

            if(diffCb + diffCr > COLOR_THRESHOLD) {
                //GET_PIXELMOD2(x, y, 0) = 0xff;
                NotCGPoint pt;
                pt.x = x;
                pt.y = y;
                solutionArray->push_back(pt);
                break;
            }
        }
        /*for(int searchBeginPx = 0; searchBeginPx < 100; searchBeginPx++) {
            int prevToothY = -1;
            
            typedef struct {
                int x;
                int y;
                int z;
            } NotCG3DPoint;
            std::vector<NotCG3DPoint> line = std::vector<NotCG3DPoint>();
            
            int prevToothCenter = searchBeginPx;
            int toothCenter = prevToothCenter + (MIN_TOOTH_SIZE);
        searchTooth:
            for(; toothCenter <= prevToothCenter + MAX_TOOTH_SIZE; toothCenter++) {
                int tooth_notRotated_Y = 0;
                int toothCenterX = toothCenter;
                int toothCenterY = tooth_notRotated_Y;
                int tooth_rotatedX = toothCenterX*cos(theta) - toothCenterY*sin(theta);
                int tooth_rotatedY = toothCenterX * sin(theta) + toothCenterY * cos(theta) + cY; //which we rotate along some angle, §L95
                if (tooth_rotatedX >= WIDTH || tooth_rotatedX < 0) {
                    continue;
                }
                if (tooth_rotatedY >= HEIGHT || tooth_rotatedY < 0) {
                    continue;
                }
                
                int toothY = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 0);
                int toothCR = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 1);
                int toothCB = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 2);
                
                if (!looksWhite(toothY, toothCR, toothCB, prevToothY)) continue;
                //now let's look for a suitable dark patch
                
                char found_dark = NO;
                int dark_rotatedX_sln = -99;
                int dark_rotatedY_sln = -99;
                for(int darkCenter = toothCenter + MIN_TOOTH_SIZE / 2; darkCenter <= toothCenter + MAX_TOOTH_SIZE / 2; darkCenter++) {
                    int dark_notRotated_Y = tooth_notRotated_Y;
                    int dark_rotatedX = darkCenter * cos(theta) - dark_notRotated_Y * sin(theta);
                    int dark_rotatedY = darkCenter * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                    if (dark_rotatedX >= WIDTH || dark_rotatedX < 0) {
                        continue;
                    }
                    if (dark_rotatedY >= HEIGHT || dark_rotatedY < 0) {
                        continue;
                    }
                    int darkY = GET_PIXELMOD1(dark_rotatedX, dark_rotatedY, 0);
                    if (abs(toothY - darkY) < THRESHOLD_WHITE_BLACK) {
                        continue;
                    }
                    if (darkY > MAX_Y_FOR_DARK_THRESHOLD) {
                        continue;
                    }
                    //check that we've gone back to white after MAX_DARK_SIZE
                    int darkEnd = darkCenter + MAX_DARK_SIZE;
                    int dark_rotatedEndX = darkEnd * cos(theta) - dark_notRotated_Y * sin(theta);
                    int dark_rotatedEndY = darkEnd * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                    if (dark_rotatedEndY < 0 || dark_rotatedEndY >= MouthHeight) continue;
                    if (dark_rotatedEndX < 0 || dark_rotatedEndX >= MouthWidth) continue;
                    int darkEndY = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 0);
                    int darkEndCr = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 1);
                    int darkEndCb = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 2);
                    if (!looksWhite(darkEndY, darkEndCr, darkEndCb, prevToothY)) {
                        continue;
                    }
                    
                    found_dark = YES;
                    dark_rotatedX_sln = dark_rotatedX;
                    dark_rotatedY_sln = dark_rotatedY;
                    
                }
                if (!found_dark) {
                    continue;
                }
                
                
                
                
                
                
                
                NotCG3DPoint coord;
                coord.x = tooth_rotatedX;
                coord.y = tooth_rotatedY;
                coord.z = 0;
                
                NotCG3DPoint darkCoord;
                darkCoord.x = dark_rotatedX_sln;
                darkCoord.y = dark_rotatedY_sln;
                darkCoord.z = 2;
                
                line.push_back(coord);
                line.push_back(darkCoord);
                prevToothY = toothY;
                prevToothCenter = toothCenter;
                toothCenter = prevToothCenter + MIN_TOOTH_SIZE;
            }
            
            if (line.size() >= EXPECT_TEETH) {
                //NSLog(@"found teeth at %@",line);
                for(int i = 0; i < line.size(); i++) {
                    NotCG3DPoint coord = line[i];
                    GET_PIXELMOD2(coord.x, coord.y, coord.z) = 0xff;
                }
            }
            
        }*/
    }
    
    //gitftwrap
    //todo: convert this to more C
    
    

    /*int leftmostX = -1;
    int leftmostY = -1;
    for(int x = 0; x < WIDTH; x++) {
        for(int y = 0; y < HEIGHT; y++) {
            if (GET_PIXELMOD2(x, y, 0)==0xff) {
                leftmostX = x;
                leftmostY = y;
                break;
            }
        }
        if (leftmostX != -1) break;
    }
    int pX = leftmostX;
    int pY = leftmostY;
    while(true) {
        int qX = -1;
        int qY = -1;
        //p --> q --> r
        
        qX = leftmostX;
        qY = leftmostY;
        for(int rX = 0; rX < WIDTH; rX++) {
            for(int rY = 0; rY < HEIGHT; rY++) {
                
                if (GET_PIXELMOD2(rX, rY, 0)!=0xff) continue;
#define TURN_LEFT 1
#define TURN_RIGHT -1
#define TURN_NONE 0
                
                float dist_p_r = pow(pX - rX,2) + pow(pY - rY,2);
                float dist_p_q = pow(pX - qX,2) + pow(pY - qY,2);
                //compute the turn
                int t = -999;
                int lside = (qX - pX) * (rY - pY) - (rX - pX) * (qY - pY);
                if (lside < 0) t = -1;
                if (lside > 0) t = 1;
                if (lside==0) t = 0;
                if (t==TURN_RIGHT || (t==TURN_NONE && dist_p_r > dist_p_q)) {
                    qX = rX;
                    qY = rY;
                }
            }
        }
        //we consider qX to be in our solution
        NotCGPoint soln;
        soln.x = qX;
        soln.y = qY;
        solutionArray->push_back(soln);
        if (qX == leftmostX && qY == leftmostY) {
            break;
        }
        pX = qX;
        pY = qY;
    }*/

    free(testimagedataMod1);
    free(testimagedataMod2);
    
    printf("solution of size %lu\n",solutionArray->size());

    return solutionArray;
    
}