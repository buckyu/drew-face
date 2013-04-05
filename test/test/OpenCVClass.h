#include <opencv2/highgui/highgui_c.h>
#include <opencv2/features2d/features2d.hpp>
#include "Detect.h"

cv::Mat *processUIImageForFace(cv::Mat *img, const char *fn, rect *outRect);
cv::Rect processUIImageForMouth(cv::Mat *img, const char *fn);

cv::Mat edgeDetectReturnOverlay(cv::Mat *img);