//
//  SmileStitcher.cpp
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "SmileStitcher.h"
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/stitching/stitcher.hpp>

#ifdef DONT_PORT
#include "FaceDetectRenamedObjCExtensions.h"
#endif

const char *stitchMouthOnFace(FileInfo *fileInfo, char *mouthImage) {
    char *ret = (char*)calloc(strlen(fileInfo->originalFileNamePath) + 5 + 1, sizeof(char));
    if(!ret) {
        //out of memory
        return NULL;
    }
    sprintf(ret, "modd-%s", fileInfo->originalFileNamePath);

    std::vector<cv::Mat> *imgs = new std::vector<cv::Mat>;
    cv::Stitcher stitcher = cv::Stitcher::createDefault(true);
    cv::Mat stitched;
    stitcher.stitch(*imgs, stitched);

#if DONT_PORT
    writeToDisk(stitched, ret);
#endif

    return ret;
}