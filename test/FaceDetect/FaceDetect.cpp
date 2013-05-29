// This is the main DLL file.

#include "stdafx.h"
#include <vector>
#include "FaceDetect.h"
#include "FaceDetectRenamed.h"
#include "SmileStitcher.h"
using namespace System::Runtime::InteropServices;

String ^FaceDetect::FaceDetector::stitchFace(FaceDetect::GeometryType ^geometryType, String ^mouth) {
	char *cmouth = (char*)(void*)Marshal::StringToHGlobalAnsi(mouth);
	FileInfo *info = (FileInfo*)malloc(sizeof(FileInfo));
	std::vector<NotCGPoint> *imagePoints = new std::vector<NotCGPoint>;
	for(int i = 0; i < geometryType->teethArea->Count; i++) {
		Point ^pt = geometryType->teethArea[i];
		NotCGPoint p;
		p.x = pt->x;
		p.y = pt->y;
		imagePoints->push_back(p);
	}
	char *filename = (char*)(void*)Marshal::StringToHGlobalAnsi(geometryType->fileName);
	info->originalFileNamePath = filename;
	info->imagePoints = imagePoints;

	printf("cmouth = %s\n", cmouth);
	printf("filename = %s\n", filename);
	//return gcnew String("foo");
	const char *ret = stitchMouthOnFace(info, cmouth);
	free(info);
	String ^result = gcnew String(ret);
	return result;
}

void FaceDetect::FaceDetector::detectFaces(FaceDetect::GeometryType ^geometryType) {
	//here is where you would call the detect function
	printf("Filename = %s\n", geometryType->fileName);

	char *str = (char*)(void*)Marshal::StringToHGlobalAnsi(geometryType->fileName);
	FileInfo *info = extractGeometry(str,"haarcascade_frontalface_default.xml","haarcascade_mcs_mouth.xml");
	if(info == NULL) {
		geometryType->fileName = gcnew String("");
		return;
	}
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	std::vector<NotCGPoint> points = *(info->imagePoints);

	geometryType->faceArea = gcnew Rect;
	geometryType->faceArea->x = info->facedetectX / info->facedetectScaleFactor;
	geometryType->faceArea->y = info->facedetectY / info->facedetectScaleFactor;
	geometryType->faceArea->width = info->facedetectW / info->facedetectScaleFactor;
	geometryType->faceArea->height = info->facedetectH / info->facedetectScaleFactor;
	geometryType->mouthArea = gcnew Rect;
	geometryType->mouthArea->x = geometryType->faceArea->x + info->mouthdetectX / info->facedetectScaleFactor;
	geometryType->mouthArea->y = geometryType->faceArea->y +info->mouthdetectY / info->facedetectScaleFactor + MAGIC_HEIGHT * geometryType->faceArea->height;
	geometryType->mouthArea->width = geometryType->faceArea->x + info->mouthdetectW / info->facedetectScaleFactor;
	geometryType->mouthArea->height = geometryType->faceArea->y + info->mouthdetectH / info->facedetectScaleFactor;



	for(int i = 0; i < (info->points)->size(); i++) {
		Point ^p = gcnew Point();
		NotCGPoint point = points[i];
		p->x = point.x;
		p->y = point.y;
		l->Add(p);
	}
	geometryType->teethArea = l;
	




}

