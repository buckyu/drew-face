// This is the main DLL file.

#include "stdafx.h"
#include <vector>
#include "FaceDetect.h"
#include "faceDetect1.h"
using namespace System::Runtime::InteropServices;

void FaceDetect::FaceDetector::detectFaces(FaceDetect::GeometryType ^geometryType) {
	//here is where you would call the detect function
	printf("Filename = %s\n", geometryType->fileName);

	char *str = (char*)(void*)Marshal::StringToHGlobalAnsi(geometryType->fileName);
	assert(strcmp(str, "C:\\test.jpg") == 0);
	FileInfo *info = extractGeometry(str);
	NotCGPoint *result = info->points;
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	for(int i = 0; i < info->numPoints; i++) {
		Point ^p = gcnew Point();
		NotCGPoint point = result[i];
		p->x = point.x;
		p->y = point.y;
		l->Add(p);
	}
	geometryType->teethArea = l;
}

