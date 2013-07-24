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
struct NCGP {
    int x;
    int y;
    
    //i'm very sorry
    bool operator<( const NCGP & n ) const {
        return this->x < n.x;   // for example
    }
        bool operator==( const NCGP & n) const {
            return this->x==n.x && this->y == n.y;
        }
};
typedef struct NCGP NotCGPoint;

//everything here is in a different coordinate space. So says Drew
typedef struct FileInfo {
    const char *originalFileNamePath;
    std::vector<NotCGPoint> *points; //points WRT the mouth
    std::vector<NotCGPoint> *imagePoints; //points WRT the image
    std::vector<NotCGPoint> *bottomLip; //this is intended purely for internal consumption, and only appears here because we've given up all appearance of good design
    float facedetectScaleFactor;
    float facedetectX;
    float facedetectY;
    float facedetectW;
    float facedetectH;
    float mouthdetectX;
    float mouthdetectY;
    float mouthdetectW;
    float mouthdetectH;
    float frontToothWidth;
} FileInfo;

FileInfo* completeDetect(char *fileName);
const char *stitchMouthOnFace(FileInfo *fileInfo, const char *mouthImage);


#endif /* defined(__DrewFace__FaceDetectExports__) */
