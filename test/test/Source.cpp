#include "faceDetect1.h"
#include <Windows.h>

int main() {
	AllocConsole();
	GetStdHandle(STD_ERROR_HANDLE);
	FileInfo *ret = extractGeometry("C:\\test.jpg");
}