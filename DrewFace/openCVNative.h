//
//  openCVNative.h
//  DrewFace
//
//  Created by Drew Crawford on 4/5/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef __DrewFace__openCVNative__
#define __DrewFace__openCVNative__

#include <iostream>

#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>

#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include "Detect.h"
cv::Mat *processUIImageForFace(cv::Mat *img, const char *haarcascade_frontalface_default_path, rect *outRect);
rect processUIImageForMouth(cv::Mat *img, const char *haarcascade_mcs_mouth_path);
cv::Mat edgeDetectReturnOverlay(cv::Mat *img) ;
#endif /* defined(__DrewFace__openCVNative__) */
