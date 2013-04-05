#ifndef __DrewFace__DrewFaceDetectPart2__
#define __DrewFace__DrewFaceDetectPart2__

#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>

#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/features2d.hpp>

#include <iostream>
#include <vector>

typedef struct {
    int x;
    int y;
} NotCGPoint;

std::vector<NotCGPoint> findTeethArea(cv::Mat image);

char looksWhite(unsigned __int8 toothY, unsigned __int8 toothCr, unsigned __int8 toothCb, unsigned __int8 prevToothY);

#endif /* defined(__DrewFace__DrewFaceDetectPart2__) */