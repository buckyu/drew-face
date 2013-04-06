// This is the main DLL file.

#include "stdafx.h"
#include <vector>
#include "FaceDetect.h"
#include "FaceDetectRenamed.h"
using namespace System::Runtime::InteropServices;

void FaceDetect::FaceDetector::detectFaces(FaceDetect::GeometryType ^geometryType) {
	//here is where you would call the detect function
	printf("Filename = %s\n", geometryType->fileName);

	char *str = (char*)(void*)Marshal::StringToHGlobalAnsi(geometryType->fileName);
	FileInfo *info = extractGeometry("c:\\test.jpg","haarcascade_frontalface_default.xml","haarcascade_mcs_mouth.xml");
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	std::vector<NotCGPoint> points = *(info->points);

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
		p->x = geometryType->mouthArea->x + point.x / info->facedetectScaleFactor;
		p->y =geometryType->mouthArea->y + point.y / info->facedetectScaleFactor;
		l->Add(p);
	}
	geometryType->teethArea = l;
	




}

