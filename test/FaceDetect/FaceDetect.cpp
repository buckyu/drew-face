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
	FileInfo *info = extractGeometry("c:\\test.jpg","C:\\Users\\dev13\\drew-face\\haarcascade_frontalface_default.xml","C:\\Users\\dev13\\drew-face\\haarcascade_mcs_mouth.xml");
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	std::vector<NotCGPoint> points = *(info->points);

	for(int i = 0; i < (info->points)->size(); i++) {
		Point ^p = gcnew Point();
		NotCGPoint point = points[i];
		p->x = point.x;
		p->y = point.y;
		l->Add(p);
	}
	geometryType->teethArea = l;
}

