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
	FileInfo *info = extractGeometry(str);
	std::vector<NotCGPoint> result = info->points;
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	for(int i = 0; i < result.size(); i++) {

		Point ^p = gcnew Point();
		p->x = 5.0;
		p->y = 6.0;
		l->Add(p);
	}
	geometryType->teethArea = l;
}

