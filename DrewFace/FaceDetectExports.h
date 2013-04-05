//
//  FaceDetectExports.h
//  DrewFace
//
//  Created by Drew Crawford on 4/5/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef __DrewFace__FaceDetectExports__
#define __DrewFace__FaceDetectExports__
#include <vector>

#include <iostream>
typedef struct {
    int x;
    int y;
} NotCGPoint;

typedef struct FileInfo {
    const char *originalFileNamePath;
    std::vector<NotCGPoint> *points;
    float facedetectScaleFactor;
    float facedetectX;
    float facedetectY;
    float facedetectW;
    float facedetectH;
    float mouthdetectX;
    float mouthdetectY;
    float mouthdetectW;
    float mouthdetectH;
} FileInfo;

FileInfo* completeDetect(char *fileName);




#endif /* defined(__DrewFace__FaceDetectExports__) */
