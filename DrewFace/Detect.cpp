//
//  Detect.c
//  DrewFace
//
//  Created by Drew Crawford on 2/11/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include <stdio.h>
#include "Detect.h"
#include <opencv2/objdetect/objdetect.hpp>



void Detect(IplImage *myImage, const char *xml_filename_utf8, rect *result, const char *targetType, const char *fn) {
    int w = myImage->width;
    int h = myImage->height;
    CvHaarClassifierCascade *cascade = (CvHaarClassifierCascade *)cvLoad(xml_filename_utf8, NULL, NULL, NULL);
    CvMemStorage *storage = cvCreateMemStorage(0);
    
    CvSeq *detections = cvHaarDetectObjects(myImage, cascade, storage, 1.05, 5, 0, cvSize(w/4,h/4), cvSize(w, h));
    
    //printf("%d Objects Detected\n",detections->total);
    
    result->x = 0;
    result->y = 0;
    result->width = 0;
    result->height = 0;
    
    if (detections->total > 0) {
        CvRect convertMe =  *(CvRect*)cvGetSeqElem(detections, 0);
        //need to use external storage because this function cleans up its storage
        result->x = convertMe.x;
        result->y = convertMe.y;
        result->width = convertMe.width;
        result->height = convertMe.height;
    }
    
    if (detections->total > 1) {
        printf("Warning, multiple %ss detected - %d - %s\n",targetType,detections->total,fn);
    }
    
    cvReleaseHaarClassifierCascade(&cascade);
    cvReleaseMemStorage(&storage);
    
    
}
