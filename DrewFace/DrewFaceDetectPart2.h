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
std::vector<NotCGPoint>* findTeethArea(cv::Mat image);
#include <stdint.h> //gets uint8_t
char looksWhite(uint8_t toothY, uint8_t toothCr, uint8_t toothCb,uint8_t prevToothY);



#endif /* defined(__DrewFace__DrewFaceDetectPart2__) */
