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
        uint8_t *dataRow = &data[y * row_stride];
        for(int x = 0; x < ret->data->width; x++) {
            dataRow[x * colorChannels + 0] = buffer[0][x*3+0];
            dataRow[x * colorChannels + 1] = buffer[0][x*3+1];
            dataRow[x * colorChannels + 2] = buffer[0][x*3+2];

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

void YCbCrToRGB(IplImage* ScrY, IplImage* ScrCb, IplImage* ScrCr, IplImage* DesR, IplImage* DesG, IplImage* DesB) {
    for(int i=0; i < ScrY->height; i++) {
        for(int j=0; j < ScrY->width; j++) {
            double Y = (uchar)(ScrY->imageData + ScrY->widthStep*i)[j];
            double Cb = (uchar)(ScrCb->imageData + ScrCb->widthStep*i)[j];
            double Cr = (uchar)(ScrCr->imageData + ScrCr->widthStep*i)[j];

            Cb = Cb -128;
            Cr = Cr -128;
            int r;
            int g;
            int b;

            (DesR->imageData + DesR->widthStep*i)[j] = (int)(1 * Y + 0 * Cb + 1.4 * Cr);
            (DesG->imageData + DesG->widthStep*i)[j] = (int)(1 * Y - 0.343 * Cb - 0.711 *Cr);
            (DesB->imageData + DesB->widthStep*i)[j] = (int)(1* Y + 1.765 * Cb + 0* Cr);
        }
    }
}

void writeJpegToFile(struct jpeg *jpeg, const char *filename, int quality) {
    /* This struct contains the JPEG compression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     * It is possible to have several such structures, representing multiple
     * compression/decompression processes, in existence at once.  We refer
     * to any one struct (and its associated working data) as a "JPEG object".
     */
    struct jpeg_compress_struct cinfo;
    /* This struct represents a JPEG error handler.  It is declared separately
     * because applications often want to supply a specialized error handler
     * (see the second half of this file for an example).  But here we just
     * take the easy way out and use the standard error handler, which will
     * print a message on stderr and call exit() if compression fails.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    struct jpeg_error_mgr jerr;
    /* More stuff */
    FILE * outfile;		/* target file */
    JSAMPROW row_pointer[1];	/* pointer to JSAMPLE row[s] */
    int row_stride;		/* physical row width in image buffer */

    /* Step 1: allocate and initialize JPEG compression object */

    /* We have to set up the error handler first, in case the initialization
     * step fails.  (Unlikely, but it could happen if you are out of memory.)
     * This routine fills in the contents of struct jerr, and returns jerr's
     * address which we place into the link field in cinfo.
     */
    cinfo.err = jpeg_std_error(&jerr);
    /* Now we can initialize the JPEG compression object. */
    jpeg_create_compress(&cinfo);

    /* Step 2: specify data destination (eg, a file) */
    /* Note: steps 2 and 3 can be done in either order. */

    /* Here we use the library-supplied code to send compressed data to a
     * stdio stream.  You can also write your own code to do something else.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to write binary files.
     */
    if ((outfile = fopen(filename, "wb")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        exit(1);
    }
    jpeg_stdio_dest(&cinfo, outfile);

    /* Step 3: set parameters for compression */

    /* First we supply a description of the input image.
     * Four fields of the cinfo struct must be filled in:
     */
    cinfo.image_width = jpeg->width; 	/* image width and height, in pixels */
    cinfo.image_height = jpeg->height;
    cinfo.input_components = jpeg->colorComponents;		/* # of color components per pixel */
    cinfo.in_color_space = JCS_RGB; 	/* colorspace of input image */
    /* Now use the library's routine to set default compression parameters.
     * (You must set at least cinfo.in_color_space before calling this,
     * since the defaults depend on the source color space.)
     */
    jpeg_set_defaults(&cinfo);
    /* Now you can set any non-default parameters you wish to.
     * Here we just illustrate the use of quality (quantization table) scaling:
     */
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);

    /* Step 4: Start compressor */

    /* TRUE ensures that we will write a complete interchange-JPEG file.
     * Pass TRUE unless you are very sure of what you're doing.
     */
    jpeg_start_compress(&cinfo, TRUE);

    /* Step 5: while (scan lines remain to be written) */
    /*           jpeg_write_scanlines(...); */

    /* Here we use the library's state variable cinfo.next_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     * To keep things simple, we pass one scanline per call; you can pass
     * more if you wish, though.
     */
    row_stride = jpeg->width * jpeg->colorComponents;	/* JSAMPLEs per row in image_buffer */

    row_pointer[0] = (uint8_t*)calloc(row_stride, sizeof(uint8_t));
    while (cinfo.next_scanline < cinfo.image_height) {
        /* jpeg_write_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could pass
         * more than one scanline at a time if that's more convenient.
         */
        for(int i = 0; i < row_stride / jpeg->colorComponents; i++) {
            uint8_t r = jpeg->data->imageData[cinfo.next_scanline * row_stride + i * jpeg->colorComponents + 0];
            uint8_t g = jpeg->data->imageData[cinfo.next_scanline * row_stride + i * jpeg->colorComponents + 1];
            uint8_t b = jpeg->data->imageData[cinfo.next_scanline * row_stride + i * jpeg->colorComponents + 2];

            row_pointer[0][i * jpeg->colorComponents + 0] = r;
            row_pointer[0][i * jpeg->colorComponents + 1] = g;
            row_pointer[0][i * jpeg->colorComponents + 2] = b;
        }
        //row_pointer[0] = (uint8_t*)& (jpeg->data->imageData[cinfo.next_scanline * row_stride]);
        (void) jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    free(row_pointer[0]);

    /* Step 6: Finish compression */

    jpeg_finish_compress(&cinfo);
    /* After finish_compress, we can close the output file. */
    fclose(outfile);
    
    /* Step 7: release JPEG compression object */
    
    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_compress(&cinfo);
    
    /* And we're done! */
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