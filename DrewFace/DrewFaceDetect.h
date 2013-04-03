//
//  DrewFaceDetect.h
//  DrewFace
//
//  Created by Drew Crawford on 3/28/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

/**Okay so let's talk about this.
 
 Basically you need to port the function extractGeometry, including whatever it needs to do its job.  Some things that it needs to do its job have been moved into this class.  Others might include OpenCV etc.  You can be pretty liberal about e.g. using an entirely different approach for resizing an image and so on.  But you should be conservative when you hit code that's doing strange image math.
 
Brief overview of the function: it accepts a filename, returns a dictionary of computed values, and has the side effect of writing one image to disk.  That's the behavior we're looking for in the port.
 
 Obviously C has no support for return values like NSDictionary*.  So I assume what you will do is either
  1) use a structish or C++ thing, and provide bindings for ObjC to maintain its existing contract as needed, or
  2) introduce a new contract, and update all the code to talk to it
 
 You are free to reorganize however, but try to minimize changes to files Feng or I might be working in.  We won't touch this one, or any new ones you create.
 
 You will see some code wrapped with the macro DONT_PORT.  This has the following meaning:
 
  1) The behavior of the code when run on ObjC target is desirable and should be preserved
  2) The behavior of the code in a .NET / production environment is not interesting and does not need to run
 
 This is about half the porting work I showed you earlier.  The other half is still coming in the form of other functions that loosely connect with this one.
 
 
 
 */

#define DONT_PORT 1


#import <Foundation/Foundation.h>
#include "DrewFaceDetectPart2.h"

#if DONT_PORT
extern NSString *docsDir;
extern NSString *originalDir;
extern NSString *originalThumbsDir;
extern NSString *extractedMouthsDir;
extern NSString *extractedMouthsEdgesDir;

extern NSString *NoFaceDir;
extern NSString *NoMouthDir;

extern NSString *testDir;
extern NSString *modelMouthDir;
#import "FindMouthsViewController.h"
#endif

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

@interface DrewFaceDetect : NSObject

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end

void setupStructures();

FileInfo *extractGeometry(const char *fileNamePath);
//WARNING: This will free the struct that is passed in!
NSMutableDictionary *objcDictOfStruct(FileInfo *dict);