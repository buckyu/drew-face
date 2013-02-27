//
//  Detect.h
//  DrewFace
//
//  Created by Drew Crawford on 2/11/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef DrewFace_Detect_h
#define DrewFace_Detect_h
#import <opencv2/highgui/highgui_c.h>

typedef struct {
    int x;
    int y;
    int width;
    int height;
} rect;

/**Detects the object and places it into the rect.
 @param myImage an IplImage
 @param xml_filename_utf8 The absolute path to haarcascade_*.xml encoded into UTF8.
 @param result a pointer to a rect (an out parameter).
 */
void Detect(IplImage *myImage, const char *xml_filename_utf8, rect *result, const char *targetType, const char *fn);
#endif
