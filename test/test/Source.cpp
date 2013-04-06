#include <stdio.h>
#include "../../DrewFace/FaceDetectRenamed.h"
int main () {
		FileInfo *info = extractGeometry("c:\\test.jpg","C:\\Users\\dev13\\drew-face\\haarcascade_frontalface_default.xml","C:\\Users\\dev13\\drew-face\\haarcascade_mcs_mouth.xml");
		printf("Successful analysis with %d points\n",info->points->size());
}