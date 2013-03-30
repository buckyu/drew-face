//
//  DrewFaceDetect.m
//  DrewFace
//
//  Created by Drew Crawford on 3/28/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#if DONT_PORT
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#endif

#include "DrewFaceDetect.h"
#include <opencv2/imgproc/imgproc_c.h>
#include "exif-data.h"
#include <stdio.h>
#include "OpenCvClass.h"
#include "jpeglib.h"
#include "jerror.h"
#include "transupp.h"

#if DONT_PORT
NSString *docsDir;
NSString *originalDir;
NSString *originalThumbsDir;
NSString *extractedMouthsDir;
NSString *extractedMouthsEdgesDir;

NSString *NoFaceDir;
NSString *NoMouthDir;

NSString *testDir;
NSString *modelMouthDir;
NSFileManager *manager;
#import "FindMouthsViewController.h"
#endif

@implementation DrewFaceDetect

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return newImage;
}

@end

void setupStructures() {
#ifdef DONT_PORT
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        originalDir = [docsDir stringByAppendingPathComponent:@"ORIGINAL"];
        originalThumbsDir = [docsDir stringByAppendingPathComponent:@"ORIGINAL_THUMBS"];
        [manager removeItemAtPath:originalThumbsDir error:NULL];
        if (![manager fileExistsAtPath:originalThumbsDir]) {
            [manager createDirectoryAtPath:originalThumbsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        extractedMouthsDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS"];
        [manager removeItemAtPath:extractedMouthsDir error:NULL];
        if (![manager fileExistsAtPath:extractedMouthsDir]) {
            [manager createDirectoryAtPath:extractedMouthsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        extractedMouthsEdgesDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS_EDGES"];
        [manager removeItemAtPath:extractedMouthsEdgesDir error:NULL];
        if (![manager fileExistsAtPath:extractedMouthsEdgesDir]) {
            [manager createDirectoryAtPath:extractedMouthsEdgesDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        NoFaceDir = [docsDir stringByAppendingPathComponent:@"NO_FACE_FOUND"];
        [manager removeItemAtPath:NoFaceDir error:NULL];
        if (![manager fileExistsAtPath:NoFaceDir]) {
            [manager createDirectoryAtPath:NoFaceDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        NoMouthDir = [docsDir stringByAppendingPathComponent:@"NO_MOUTH_FOUND"];
        [manager removeItemAtPath:NoMouthDir error:NULL];
        if (![manager fileExistsAtPath:NoMouthDir]) {
            [manager createDirectoryAtPath:NoMouthDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    });

#endif
}

struct jpeg {
    cv::Mat *data;
    JDIMENSION width;
    JDIMENSION height;
    int colorComponents;
    J_COLOR_SPACE colorSpace;
};

struct jpeg *loadJPEGFromFile(const char *filename, int maxDimension);

struct jpeg *loadJPEGFromFile(const char *filename) {
    return loadJPEGFromFile(filename, INT_MAX);
}

struct jpeg *loadJPEGFromFile(const char *filename, int maxDimension) {
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     */
    struct jpeg_decompress_struct *cinfo = (struct jpeg_decompress_struct*)malloc(sizeof(struct jpeg_decompress_struct));

    /* More stuff */
    FILE * infile;		/* source file */
    JSAMPARRAY buffer;	/* Output row buffer */
    int row_stride;		/* physical row width in output buffer */
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

    //Scale down to maxDimension if necessary
    int w = cinfo->image_width;
    int h = cinfo->image_height;
    int max = (w > h)? w : h;
    if(max > maxDimension) {
        //facedetectScaleFactor = maxDimension / (float)max;
        cinfo->scale_num = maxDimension;
        cinfo->scale_denom = max;
    }

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

    ret->colorSpace = cinfo->jpeg_color_space;
    ret->colorComponents = cinfo->output_components;
    ret->width = cinfo->output_width;
    ret->height = cinfo->output_height;

    if(ret->colorComponents == 3) {
        cv::Mat M(ret->width, ret->height, CV_8UC3);
        ret->data = &M;
    } else if(ret->colorComponents == 1) {
        cv::Mat M(ret->width, ret->height, CV_8UC1);
        ret->data = &M;
    } else {
        //unusual colorspace
        return NULL;
    }

    /* JSAMPLEs per row in output buffer */
    row_stride = (*cinfo).output_width * (*cinfo).output_components;
    /* Make a one-row-high sample array that will go away when done with image */
    buffer = (*cinfo->mem->alloc_sarray)((j_common_ptr) cinfo, JPOOL_IMAGE, row_stride, 1);

    /* Step 6: while (scan lines remain to be read) */
    /*           jpeg_read_scanlines(...); */

    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
    while(cinfo->output_scanline < cinfo->output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        (void) jpeg_read_scanlines(cinfo, buffer, 1);
        memcpy(&(ret->data->data[cinfo->output_scanline * ret->colorComponents * ret->width]), buffer[0], sizeof(unsigned char));
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
    free(jpg);
}

/* Show the tag name and contents if the tag exists */
static char *get_tag(ExifData *d, ExifIfd ifd, ExifTag tag)
{
    /* See if this tag exists */
    ExifEntry *entry = exif_content_get_entry(d->ifd[ifd],tag);
    if (entry) {
        char *ret = (char*)calloc(1024, sizeof(char));

        /* Get the contents of the tag in human-readable form */
        exif_entry_get_value(entry, ret, sizeof(ret));

        return ret;
    }
    return NULL;
}

int exifOrientation(const char *filename) {
    ExifData *ed = exif_data_new_from_file(filename);
    char *orientation = get_tag(ed, EXIF_IFD_0, EXIF_TAG_ORIENTATION);
    if(strlen(orientation) > 1 || orientation[0] < '1' || orientation[0] > '8') {
        return 1;
    }
    return orientation[0] - '1' + 1;
}

//it's up to the caller to close out image
//it's up to the caller to close out the returned structure
struct jpeg_compress_struct *transformImage(struct jpeg_decompress_struct *image, jpeg_transform_info info) {
    info.trim = true;
    if(!jtransform_request_workspace(image, &info)) {
        return NULL;
    }

    struct jpeg_compress_struct *ret = (struct jpeg_compress_struct*)malloc(sizeof(jpeg_compress_struct));
    if(!ret) {
        return NULL;
    }
    struct jpeg_error_mgr jdstderr;
    ret->err = jpeg_std_error(&jdstderr);
    jpeg_create_compress(ret);

    jvirt_barray_ptr *src_oef_arrays = jpeg_read_coefficients(image);
    jpeg_copy_critical_parameters(image, ret);
    jvirt_barray_ptr *dst_oef_arrays = jtransform_adjust_parameters(image, ret, src_oef_arrays, &info);
    jpeg_write_coefficients(ret, dst_oef_arrays);

    jtransform_execute_transform(image, ret, src_oef_arrays, &info);

    return ret;
}

#warning Now I need some not-terrible way to turn the jpeg_compress_struct from transformImage back into a jpeg_decompress_struct I can use anywhere (we're going to be cropping later...)

FileInfo *extractGeometry(const char *fileNamePath) {
#if DONT_PORT
    NSString *simpleFileName = [[NSString stringWithCString:fileNamePath encoding:NSMacOSRomanStringEncoding] lastPathComponent];
#endif

    // Find Mouths in original images here

    // Orient images for face detection (EXIF Orientation = 0)
    int orientation = exifOrientation(fileNamePath);

    UIImage *testimage = [UIImage imageWithContentsOfFile:fileNamePath];
    if (orientation == 6) {
        // rotate CGImageRef data
        CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0];
        testimage = [UIImage imageWithCGImage:rotatedImageRef];
        CGImageRelease(rotatedImageRef);
    } else if (orientation == 3) {
        CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:M_PI];
        testimage = [UIImage imageWithCGImage:rotatedImageRef];
        CGImageRelease(rotatedImageRef);
    } else if (orientation > 1) {
        printf("%s Orientation %d not 0, 1 or 6. Need to accommodate here", fileNamePath, orientation);
    }

    // Scale down to 1024 max dimension for speed optimization of face detect
    int w = (int)testimage.size.width;
    int h = (int)testimage.size.height;
    int maxDimension = w>h? w : h;
    CGFloat facedetectScaleFactor = 1.0;
    if (maxDimension > 1024) {
        facedetectScaleFactor = 1024.0 / (CGFloat)maxDimension;
    }
    CGSize scaledDownSize = CGSizeMake(facedetectScaleFactor*w, facedetectScaleFactor*h);
    UIImage *scaledImage = [self imageWithImage:testimage scaledToSize:scaledDownSize];

    // search for face in scaledImage
    // OpenCV Processing Called Here for Face Detect

    // testimage - faceRectInScaledOrigImage is set by delegate method call
    OpenCvClass *ocv = [OpenCvClass new];
    rect faceRect;
    testimage = [ocv processUIImageForFace:scaledImage fromFile:fileNamePath outRect:&faceRect];
    if ((faceRect.width == 0) || (faceRect.height == 0)) {
        printf("NO FACE in %s", fileNamePath);
        return NULL;
    }

    // extract bottom half of face from COLOR image
    CGImageRef cutBottomHalfFaceRef = CGImageCreateWithImageInRect(testimage.CGImage, CGRectMake((int)(faceRect.x), (int)(faceRect.y+0.66*faceRect.height), (int)(faceRect.width), (int)(0.34*faceRect.height)));

    // locate mouth in bottom half of greyscale face image
    UIImage *bottomhalffaceImage = [UIImage imageWithCGImage:cutBottomHalfFaceRef];
    // do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
    // bottomhalffaceImage = [ocv greyTheImage:bottomhalffaceImage];

    //int mouthIdx = -1;
    CGRect mouthRectInBottomHalfOfFace = CGRectMake(0,0,0,0);

    // OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
    mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:bottomhalffaceImage fromFile:fileNamePath];
    // BruteForce Processing Called Here - search for mouth in bottom half of greyscale face
    // using MODELMOUTHxxx.png files in /MODEL_MOUTHS/
    //[self processUIImageForMouth:bottomhalffaceImage returnRect:&mouthRectInBottomHalfOfFace closestMouthMatch:&mouthIdx fileName:fileName];

    if ((mouthRectInBottomHalfOfFace.size.width == 0) || (mouthRectInBottomHalfOfFace.size.height == 0)) {
        printf("NO MOUTH in %s", fileNamePath);
#if DONT_PORT
        [manager copyItemAtPath:[NSString stringWithCString:fileNamePath encoding:NSMacOSRomanStringEncoding] toPath:[NoMouthDir stringByAppendingPathComponent:simpleFileName] error:nil];
#endif
        return NULL;
    }

    // extract mouth from face
    CGImageRef cutMouthRef = CGImageCreateWithImageInRect(bottomhalffaceImage.CGImage, CGRectMake(mouthRectInBottomHalfOfFace.origin.x, mouthRectInBottomHalfOfFace.origin.y, mouthRectInBottomHalfOfFace.size.width, mouthRectInBottomHalfOfFace.size.height));
    UIImage *mouthImage = [UIImage imageWithCGImage:cutMouthRef];
    CGImageRelease(cutMouthRef);

    UIImage *processedMouthImage = nil;
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
        processedMouthImage = [ocv edgeDetectReturnOverlay:mouthImage];
    }

    // write mouth images to EXTRACTED_MOUTHS directory
#if DONT_PORT
    NSData *dataToWrite = UIImageJPEGRepresentation(mouthImage, 0.8);
    NSString *thumbPath = [extractedMouthsDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite writeToFile:thumbPath atomically:YES];
#endif

    //processedMouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    if ((faceRect.width > 0) && (faceRect.height > 0)) {
#ifdef DONT_PORT
        FindMouthsViewController *dvc = [[FindMouthsViewController alloc] init];
        processedMouthImage = [dvc lookForTeethInMouthImage:mouthImage];
#endif
        //processedMouthImage = [self lookForTeethInMouthImage:mouthImage];

        if (!((processedMouthImage.size.width>0) && (processedMouthImage.size.height>0))) {
            printf("NO TEETH in %s", fileNamePath);
            return NULL;
        }
    }

    // color images here of mouth area

    CGDataProviderRef myDataProvider = CGImageGetDataProvider(processedMouthImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);

    w = (int)processedMouthImage.size.width;
    h = (int)processedMouthImage.size.height;
    uint8_t *mutablebuffer = (uint8_t *)malloc(w*h*3);
    uint8_t *mutablebuffer4 = (uint8_t *)malloc(w*h*4);

    memcpy(&mutablebuffer[0],testimagedata,w*h*3);

    for (int i=0; i<h; i++) {
        for (int j=0; j<w; j++) {
            int sum = 0;
            sum += *(mutablebuffer + i*w*3 + j*3 + 0);
            sum += *(mutablebuffer + i*w*3 + j*3 + 1);
            sum += *(mutablebuffer + i*w*3 + j*3 + 2);

            memcpy((mutablebuffer4 + i*w*4 + j*4), (mutablebuffer + i*w*3 + j*3), 3);
            //bzero((mutablebuffer4 + i*w*4 + j*4), 3);
        }
    }
    CFRelease(pixelData);

    // show image on iPhone view

    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(processedMouthImage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(processedMouthImage.CGImage);

    CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer4, w, h, 8, w*4,colorspaceRef, bitmapInfo);

    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);

    // show MODIFIED  image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];

    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);

    free(mutablebuffer);
    free(mutablebuffer4);

    // write mouth images to EXTRACTED_MOUTHS_EDGES directory
    dataToWrite = UIImageJPEGRepresentation(modifiedImage, 0.8);
#ifdef DONT_PORT
    thumbPath = [extractedMouthsEdgesDir stringByAppendingPathComponent:simpleFileName];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
#else
    thumbPath = some reasonable path?
#endif
    [dataToWrite writeToFile:thumbPath atomically:YES];

    FileInfo *ret = (FileInfo*)malloc(sizeof(FileInfo));
    ret->originalFileNamePath = fileNamePath;
    ret->facedetectScaleFactor = facedetectScaleFactor;
    ret->facedetectX = faceRect.x;
    ret->facedetectY = faceRect.y;
    ret->facedetectW = faceRect.width;
    ret->facedetectH = faceRect.height;
    ret->mouthdetectX = mouthRectInBottomHalfOfFace.origin.x;
    ret->mouthdetectY = mouthRectInBottomHalfOfFace.origin.y;
    ret->mouthdetectW = mouthRectInBottomHalfOfFace.size.width;
    ret->mouthdetectH = mouthRectInBottomHalfOfFace.size.height;
    
    return ret;
}

NSMutableDictionary *objcDictOfStruct(FileInfo *dict) {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];

    ret[@"originalFileName"] = [NSString stringWithCString:dict->originalFileNamePath encoding:NSMacOSRomanStringEncoding];
    ret[@"facedetectScaleFactor"] = @(dict->facedetectScaleFactor);
    ret[@"facedetectX"] = @(dict->facedetectX);
    ret[@"facedetectY"] = @(dict->facedetectY);
    ret[@"facedetectW"] = @(dict->facedetectW);
    ret[@"facedetectH"] = @(dict->facedetectH);
    ret[@"mouthdetectX"] = @(dict->mouthdetectX);
    ret[@"mouthdetectY"] = @(dict->mouthdetectY);
    ret[@"mouthdetectW"] = @(dict->mouthdetectW);
    ret[@"mouthdetectH"] = @(dict->mouthdetectH);

    free(dict);
    return ret;
}