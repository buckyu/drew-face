// This is the main DLL file.

#include "stdafx.h"
#include <vector>
#include "FaceDetect.h"

void FaceDetect::FaceDetector::detectFaces(FaceDetect::GeometryType ^geometryType) {
	//here is where you would call the detect function
	std::vector<int> result; //would actually be NotCGPoint, but with the current state of the codebase there's not a good way to import it
	System::Collections::Generic::List<Point^> ^l = gcnew System::Collections::Generic::List<Point^>();
	for(int i = 0; i < result.size(); i++) {

		Point ^p = gcnew Point();
		p->x = 5.0;
		p->y = 6.0;
		l->Add(p);
	}
	geometryType->teethArea = l;
}

