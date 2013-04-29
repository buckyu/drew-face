//
//  FaceDetectHelpers.cpp
//  DrewFace
//
//  Created by Bion Oren on 4/24/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "jpegHelpers.h"
#include <opencv2/imgproc/imgproc_c.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "exif-data.h"
#include "jerror.h"

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
    if (!ed) return 1;
    char *orientation = get_tag(ed, EXIF_IFD_0, EXIF_TAG_ORIENTATION);
    if (!orientation) {
        return 1;
    }
    if(strlen(orientation) > 1 || orientation[0] < '1' || orientation[0] > '8') {
        return 1;
    }
    return orientation[0] - '1' + 1;
}

struct jpeg *loadJPEGFromFile(const char *filename, int colorChannels) {
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
    cinfo->output_components = colorChannels;
    ret->colorComponents = cinfo->output_components;
    ret->width = cinfo->output_width;
    ret->height = cinfo->output_height;

    ret->data = cvCreateImage(cvSize(ret->width, ret->height), IPL_DEPTH_8U, colorChannels);

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
    uint8_t *data = (uint8_t*) ret->data->imageData;
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
            data[y * ret->data->width * colorChannels + x * colorChannels + 0] = buffer[0][x*3+0];
            data[y * ret->data->width * colorChannels + x * colorChannels + 1] = buffer[0][x*3+1];
            data[y * ret->data->width * colorChannels + x * colorChannels + 2] = buffer[0][x*3+2];

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

//http://stackoverflow.com/questions/2289690/opencv-how-to-rotate-iplimage
cv::Mat *rotateImage(const cv::Mat& source, double angle) {
    cv::Point2f src_center(source.cols/2.0F, source.rows/2.0F);
    cv::Mat rot_mat = getRotationMatrix2D(src_center, angle * 180 / M_PI, 1.0);
    cv::Mat *dst = new cv::Mat;
    warpAffine(source, *dst, rot_mat, source.size());
    return dst;
}