//
//  FaceDetect.c
//  DrewFace
//
//  Created by Drew Crawford on 2/11/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include <stdio.h>
#include "FaceDetect.h"



void faceDetect(IplImage *myImage, const char *xml_filename_utf8, rect *result) {
    int w = myImage->width;
    int h = myImage->height;
    CvHaarClassifierCascade *cascade = (CvHaarClassifierCascade *)cvLoad(xml_filename_utf8, NULL, NULL, NULL);
    CvMemStorage *storage = cvCreateMemStorage(0);
    
    CvSeq *faces = cvHaarDetectObjects(myImage, cascade, storage, 1.1, 3, 0, cvSize(w/5,w/5), cvSize(w, h));
    
    printf("%d Faces Detected\n",faces->total);
    
    if (faces->total > 0) {
        CvRect convertMe =  *(CvRect*)cvGetSeqElem(faces, 0);
        //need to use external storage because this function cleans up its storage
        result->x = convertMe.x;
        result->y = convertMe.y;
        result->width = convertMe.width;
        result->height = convertMe.height;
        
    } if (faces->total > 1) {
        printf("Warning, multiple faces detected\n");
    }
    cvReleaseHaarClassifierCascade(&cascade);
    cvReleaseMemStorage(&storage);
    
    
}
