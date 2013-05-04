//
//  jpegHelpers.h
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef __DrewFace__jpegHelpers__
#define __DrewFace__jpegHelpers__

#include <stdio.h>
#include "jpeglib.h"
#include <opencv2/imgproc/imgproc.hpp>

struct jpeg {
    IplImage *data;
    JDIMENSION width;
    JDIMENSION height;
    int colorComponents;
    J_COLOR_SPACE colorSpace;
};

int exifOrientation(const char *filename);
struct jpeg *loadJPEGFromFile(const char *filename, int colorChannels);
///quality is 0..100
void writeJpegToFile(struct jpeg *jpeg, const char *filename, int quality);
void freeJpeg(struct jpeg *jpg);
cv::Mat *rotateImage(const cv::Mat& source, double angle);

#endif /* defined(__DrewFace__jpegHelpers__) */