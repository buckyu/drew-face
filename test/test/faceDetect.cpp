#include <stdio.h>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2\imgproc\imgproc.hpp>
#include "exif-data.h"
#include "OpenCvClass.h"
#include "jpeglib.h"
#include "jerror.h"
#include "faceDetect2.h"
#define _USE_MATH_DEFINES
#include <math.h>

extern "C"
{
	__declspec(dllexport) typedef struct FileInfo {
		const char *originalFileNamePath;
		NotCGPoint *points;
		int numPoints;
		float facedetectScaleFactor;
		float facedetectX;
		float facedetectY;
		float facedetectW;
		float facedetectH;
		float mouthdetectX;
		float mouthdetectY;
		float mouthdetectW;
		float mouthdetectH;
	} FileInfo;

	struct jpeg {
		IplImage *data;
		JDIMENSION width;
		JDIMENSION height;
		int colorComponents;
		J_COLOR_SPACE colorSpace;
	};

	struct jpeg *loadJPEGFromFile(const char *filename) {
		/* This struct contains the JPEG decompression parameters and pointers to
		 * working space (which is allocated as needed by the JPEG library).
		 */
		struct jpeg_decompress_struct *cinfo = (struct jpeg_decompress_struct*)malloc(sizeof(struct jpeg_decompress_struct));

		/* More stuff */
		FILE * infile;		/* source file */
		struct jpeg_error_mgr jerr;

		/* In this example we want to open the input file before doing anything else,
		 * so that the setjmp() error recovery below can assume the file is open.
		 * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
		 * requires it in order to read binary files.
		 */

		if((infile = fopen(filename, "rb")) == NULL) {
			fprintf(stderr, "can't open %s\n", filename);
			return NULL;
		}

		/* Step 1: allocate and initialize JPEG decompression object */

		(*cinfo).err = jpeg_std_error(&jerr);

		/* Now we can initialize the JPEG decompression object. */
		jpeg_create_decompress(cinfo);

		/* Step 2: specify data source (eg, a file) */

		jpeg_stdio_src(cinfo, infile);

		/* Step 3: read file parameters with jpeg_read_header() */

		(void) jpeg_read_header(cinfo, TRUE);
		/* We can ignore the return value from jpeg_read_header since
		 *   (a) suspension is not possible with the stdio data source, and
		 *   (b) we passed TRUE to reject a tables-only JPEG file as an error.
		 * See libjpeg.txt for more info.
		 */

		/* Step 4: set parameters for decompression */

		/* Step 5: Start decompressor */

		(void) jpeg_start_decompress(cinfo);
		/* We can ignore the return value since suspension is not possible
		 * with the stdio data source.
		 */

		/* We may need to do some setup of our own at this point before reading
		 * the data.  After jpeg_start_decompress() we have the correct scaled
		 * output image dimensions available, as well as the output colormap
		 * if we asked for color quantization.
		 * In this example, we need to make an output work buffer of the right size.
		 */

		//setup our return datastructure
		struct jpeg *ret = (struct jpeg*)malloc(sizeof(struct jpeg));
		if(!ret) {
			//out of memory
			return NULL;
		}

		assert(cinfo->output_components == 3);
		ret->colorSpace = cinfo->jpeg_color_space;
		cinfo->output_components = 4;
		ret->colorComponents = cinfo->output_components;
		ret->width = cinfo->output_width;
		ret->height = cinfo->output_height;

		ret->data = cvCreateImage(cvSize(ret->width, ret->height), IPL_DEPTH_8U, 4);

		/* JSAMPLEs per row in output buffer */
		int row_stride = cinfo->output_width * cinfo->output_components; /* physical row width in output buffer */
		/* Make a one-row-high sample array that will go away when done with image */
		JSAMPARRAY buffer = (*cinfo->mem->alloc_sarray)((j_common_ptr) cinfo, JPOOL_IMAGE, row_stride, 1); /* Output row buffer */

		/* Step 6: while (scan lines remain to be read) */
		/*           jpeg_read_scanlines(...); */

		/* Here we use the library's state variable cinfo.output_scanline as the
		 * loop counter, so that we don't have to keep track ourselves.
		 */
		assert(ret->data->widthStep >= row_stride);
		for(int y = 0; y < ret->data->height; y++) {
        
			/* jpeg_read_scanlines expects an array of pointers to scanlines.
			 * Here the array is only one element long, but you could ask for
			 * more than one scanline at a time if that's more convenient.
			 */
			//typeof(cinfo->output_scanline) scanline = cinfo->output_scanline;
			(void) jpeg_read_scanlines(cinfo, buffer, 1);
			//assert(scanline * ret->data->widthStep + row_stride < ret->data->imageSize);
			//memcpy(&(ret->data->imageData[scanline * ret->data->widthStep]), buffer[0], row_stride);
			for(int x = 0; x < ret->data->width; x++) {
				uint8_t *data = (uint8_t*) ret->data->imageData;
            
				data[y * ret->data->width * 4 + x * 4 + 0] = buffer[0][x*3+0];
				data[y * ret->data->width * 4 + x * 4 + 1] = buffer[0][x*3+1];
				data[y * ret->data->width * 4 + x * 4 + 2] = buffer[0][x*3+2];

			}
		}

		/* Step 7: Finish decompression */

		(void) jpeg_finish_decompress(cinfo);
		/* We can ignore the return value since suspension is not possible
		 * with the stdio data source.
		 */

		/* Step 8: Release JPEG decompression object */

		/* After finish_decompress, we can close the input file.
		 * Here we postpone it until after no more JPEG errors are possible,
		 * so as to simplify the setjmp error logic above.  (Actually, I don't
		 * think that jpeg_destroy can do an error exit, but why assume anything...)
		 */
		jpeg_destroy_decompress(cinfo);
		fclose(infile);
    
		/* At this point you may want to check to see whether any corrupt-data
		 * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
		 */
    
		/* And we're done! */
		return ret;
	}

	void freeJpeg(struct jpeg *jpg) {
		/* This is an important step since it will release a good deal of memory. */
		//delete jpg->data; (apparently opencv does its own memory management?
		cvReleaseImage(&jpg->data);
		free(jpg);
	}

	__declspec(dllexport) FileInfo *extractGeometry(const char *fileNamePath) {
		printf("processing image %s",fileNamePath);
		// Find Mouths in original images here

		struct jpeg *jpeg = loadJPEGFromFile(fileNamePath);
		float facedetectScaleFactor = 1;
		cv::Mat scaledImg;
		{
			int w = jpeg->width;
			int h = jpeg->height;
			int max = (w > h)? w : h;
			if( max > 1024) {
				//facedetectScaleFactor = maxDimension / (float)max;
				cv::Mat mat = jpeg->data;
				facedetectScaleFactor = 1024.0 / max;
				cv::resize(mat, scaledImg, cv::Size(w * facedetectScaleFactor, h * facedetectScaleFactor), 0, 0);
			} else {
				scaledImg = jpeg->data;
			}
		}

		cv::Mat *rotatedImage = &scaledImg;

		// search for face in scaledImage
		// OpenCV Processing Called Here for Face Detect

		// testimage - faceRectInScaledOrigImage is set by delegate method call
		rect faceRect;

		cv::Mat *testimage = processUIImageForFace(rotatedImage, fileNamePath, &faceRect);

		if ((faceRect.width == 0) || (faceRect.height == 0)) {
			printf("NO FACE in %s\n", fileNamePath);
			return NULL;
		}

		// extract bottom half of face from COLOR image
		// locate mouth in bottom half of greyscale face image
		IplImage testImageImage = *testimage;
		cv::Rect roi = cvRect((int)(faceRect.x), (int)(faceRect.y+0.66*faceRect.height), (int)(faceRect.width), (int)(0.34*faceRect.height));
		cvSetImageROI(&testImageImage, roi);
		IplImage *cropImage = cvCreateImage(cvGetSize(&testImageImage), testImageImage.depth, testImageImage.nChannels);
		cvCopy(&testImageImage, cropImage);
		cvResetImageROI(&testImageImage);
		cv::Mat bottomhalffaceImage = cropImage;
		//NSData *testData = UIImageJPEGRepresentation([OpenCvClass UIImageFromCVMat:bottomhalffaceImage], 0.8);

		// do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
		// bottomhalffaceImage = [ocv greyTheImage:bottomhalffaceImage];

		//int mouthIdx = -1;
		cv::Rect mouthRectInBottomHalfOfFace = cvRect(0,0,0,0);

		// OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
		mouthRectInBottomHalfOfFace = processUIImageForMouth(&bottomhalffaceImage, fileNamePath);
		// BruteForce Processing Called Here - search for mouth in bottom half of greyscale face
		// using MODELMOUTHxxx.png files in /MODEL_MOUTHS/
		//[self processUIImageForMouth:bottomhalffaceImage returnRect:&mouthRectInBottomHalfOfFace closestMouthMatch:&mouthIdx fileName:fileName];

		if ((mouthRectInBottomHalfOfFace.width == 0) || (mouthRectInBottomHalfOfFace.height == 0)) {
			printf("NO MOUTH in %s\n", fileNamePath);
			return NULL;
		}

		// extract mouth from face
		testImageImage = bottomhalffaceImage;
		roi = cvRect(mouthRectInBottomHalfOfFace.x, mouthRectInBottomHalfOfFace.y, mouthRectInBottomHalfOfFace.width, mouthRectInBottomHalfOfFace.height);
		cvSetImageROI(&testImageImage, roi);
		cropImage = cvCreateImage(cvGetSize(&testImageImage), testImageImage.depth, testImageImage.nChannels);
		cvCopy(&testImageImage, cropImage);
		cvResetImageROI(&testImageImage);
		cv::Mat mouthImage = cropImage;

		cv::Mat processedMouthImage;
		if ((faceRect.width > 0) && (faceRect.height > 0)) {
			processedMouthImage = edgeDetectReturnOverlay(&mouthImage);
		}

		//processedMouthImage = [ocv edgeDetectReturnEdges:mouthImage];
		NotCGPoint *points = NULL;
		int numPoints = 0;
		if ((faceRect.width > 0) && (faceRect.height > 0)) {
			std::vector<NotCGPoint> pointList = findTeethArea(mouthImage);
			points = (NotCGPoint*)calloc(pointList.size(), sizeof(NotCGPoint));
			for(std::vector<NotCGPoint>::size_type i = 0; i < pointList.size(); ++i) {
				NotCGPoint point = pointList[i];
				points[i] = point;
			}
		}
		freeJpeg(jpeg);

		FileInfo *ret = (FileInfo*)malloc(sizeof(FileInfo));
		ret->originalFileNamePath = fileNamePath;
		ret->points = points;
		ret->numPoints = numPoints;
		ret->facedetectScaleFactor = facedetectScaleFactor;
		ret->facedetectX = faceRect.x;
		ret->facedetectY = faceRect.y;
		ret->facedetectW = faceRect.width;
		ret->facedetectH = faceRect.height;
		ret->mouthdetectX = mouthRectInBottomHalfOfFace.x;
		ret->mouthdetectY = mouthRectInBottomHalfOfFace.y;
		ret->mouthdetectW = mouthRectInBottomHalfOfFace.width;
		ret->mouthdetectH = mouthRectInBottomHalfOfFace.height;

		return ret;
	}
}