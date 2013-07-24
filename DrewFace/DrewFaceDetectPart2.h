//
//  DrewFaceDetectPart2.h
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef __DrewFace__DrewFaceDetectPart2__
#define __DrewFace__DrewFaceDetectPart2__
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>

#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/features2d.hpp>

#include <iostream>
#include <vector>

#include "FaceDetectExports.h"
std::vector<NotCGPoint>* findTeethArea(cv::Mat image, int *toothSize, std::vector<NotCGPoint> *bottomLip);
#include <stdint.h> //gets uint8_t
char looksWhite(uint8_t toothY, uint8_t toothCr, uint8_t toothCb,uint8_t prevToothY);

cv::Mat findTeethAreaDebug(cv::Mat image, std::vector<NotCGPoint> *area, int *toothSize, std::vector<NotCGPoint> *bottomLip);

//y = ax^2 + bx + c
float quadRegA(NotCGPoint p1, NotCGPoint p2, NotCGPoint p3);

#endif /* defined(__DrewFace__DrewFaceDetectPart2__) */
