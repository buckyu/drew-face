// FaceDetect.h

#pragma once

using namespace System;

namespace FaceDetect {

	public ref class FaceDetector {

	public:
		static void detectFaces(FaceDetect::GeometryType ^geometryType);
	};
}