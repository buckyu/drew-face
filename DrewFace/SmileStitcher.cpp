//
//  SmileStitcher.cpp
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "SmileStitcher.h"
#include <opencv2/highgui/highgui_c.h>
#include "jpegHelpers.h"

#ifdef DONT_PORT
#include "FaceDetectRenamedObjCExtensions.h"
#endif

const char *stitchMouthOnFace(FileInfo *fileInfo, const char *mouthImage) {
    char *ret = (char*)calloc(strlen(fileInfo->originalFileNamePath) + 9 + 1, sizeof(char));
    if(!ret) {
        //out of memory
        return NULL;
    }
    sprintf(ret, "%s-replaced", fileInfo->originalFileNamePath);

    std::vector<cv::Mat> *imgs = new std::vector<cv::Mat>;
    jpeg *face = loadJPEGFromFile(fileInfo->originalFileNamePath, 4);
    imgs->push_back(face->data);
    jpeg *mouth = loadJPEGFromFile(mouthImage, 4);
    imgs->push_back(mouth->data);
    return ret;

    CvRect mouthRect = cvRect(fileInfo->mouthdetectX, fileInfo->mouthdetectY, fileInfo->mouthdetectW, fileInfo->mouthdetectH);
    IplImage *faceMat = face->data;
    cv::Mat mouthMat = mouth->data;
    cv::Mat smallMouthMat;
    cv::resize(mouthMat, smallMouthMat, cv::Size(fileInfo->mouthdetectW, fileInfo->mouthdetectH));
    IplImage smallMouth = smallMouthMat;

    //http://stackoverflow.com/questions/14063070/overlay-a-smaller-image-on-a-larger-image-python-opencv
    //also, SERIOUSLY: jpegs do NOT have alpha channels!!!
    /**
     s_img = cv2.imread("smaller_image.png", -1)
     for c in range(0,3):
        l_img[y_offset:y_offset+s_img.shape[0], x_offset:x_offset+s_img.shape[1], c] =
                    s_img[:,:,c] * (s_img[:,:,3]/255.0) +  l_img[y_offset:y_offset+s_img.shape[0], x_offset:x_offset+s_img.shape[1], c] * (1.0 - s_img[:,:,3]/255.0)
     */
#define IDX(mat, c, x, y) ((uint8_t*)(mat)->imageData)[((y) * (mat)->width * 4 + (x) * 4 + (c))]
    for(int x = mouthRect.x, mx = 0; x < mouthRect.x + mouthRect.height; x++, mx++) {
        for(int y = mouthRect.y, my = 0; y < mouthRect.y + mouthRect.height; y++, my++) {
            for(int c = 0; c < 3; c++) {
                //uint8_t *data = (uint8_t*) ret->data->imageData;
                //data[y * ret->data->width * colorChannels + x * colorChannels + 0] = buffer[0][x*3+0];
                IDX(faceMat, c, x, y) = IDX(&smallMouth, c, mx, my) * IDX(&smallMouth, 3, mx, my)/255.0 + IDX(faceMat, c, x, y) * (1.0 - IDX(&smallMouth, 3, mx, my)/255.0);
            }
        }
    }
#undef IDX
    
    freeJpeg(face);
    freeJpeg(mouth);

    cv::Mat outMatrix = faceMat;
#if DONT_PORT
    writeReplaceToDisk(outMatrix, ret);
#endif

    return ret;
}