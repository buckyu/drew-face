#ifndef __DrewFace__DrewFaceDetectPart1__
#define __DrewFace__DrewFaceDetectPart1__

#include "faceDetect2.h"

//__declspec(dllexport) typedef struct FileInfo
typedef struct FileInfo {
	const char *originalFileNamePath;
	NotCGPoint *points;
	int numPoints;
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

FileInfo *extractGeometry(const char *fileNamePath);
char *getAndPrintCurrentWorkingDirectory();

#endif