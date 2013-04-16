//
//  FaceDetectRenamedObjCExtensions.m
//  DrewFace
//
//  Created by Drew Crawford on 4/9/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FaceDetectRenamedObjCExtensions.h"
#import "OpenCvClass.h"
#import "FindMouthsViewController+CPlusPlusExtensions.h"
void writeToDisk(cv::Mat mtx,const char *fullPath) {


    NSData *dataToWrite = UIImagePNGRepresentation([OpenCvClass UIImageFromCVMat:mtx]);
    assert(dataToWrite);
    NSString *path = [NSString stringWithFormat:@"%s",fullPath];
    NSString *simpleFileName = [path lastPathComponent];
    UIImage *teethDetect = [[[FindMouthsViewController alloc] init] lookForTeethInMouthImage:[OpenCvClass UIImageFromCVMat:mtx]];
    
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    

    NSString *extractedMouthsDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS"];
    NSString *extractedTeethDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS_EDGES"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:extractedMouthsDir withIntermediateDirectories:YES attributes:nil error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:extractedTeethDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *thumbPath = [extractedMouthsDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite writeToFile:thumbPath atomically:YES];
    
    dataToWrite = UIImagePNGRepresentation(teethDetect);
    thumbPath = [extractedTeethDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite writeToFile:thumbPath atomically:YES];

}
