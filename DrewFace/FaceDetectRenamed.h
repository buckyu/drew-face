//
//  FaceDetectRenamed.h
//  DrewFace
//
//  Created by Drew Crawford on 4/5/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#ifndef __DrewFace__FaceDetectRenamed__
#define __DrewFace__FaceDetectRenamed__

#define MAGIC_HEIGHT .66

#include <iostream>
#include "FaceDetectExports.h"

FileInfo *extractGeometry(const char *fileNamePath, const char* face_haar_cascade_path,const char *mouth_haar_casecade_path);


#endif /* defined(__DrewFace__FaceDetectRenamed__) */
