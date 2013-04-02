//
//  DrewFaceDetectPart2.cpp
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "DrewFaceDetectPart2.h"


std::vector<NotCGPoint> findTeethArea(cv::Mat image) {
    //originally: mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //this implementation looks approximately in-place to me
    //cv::blur(myCvMat, edges, cv::Size(4,4));
    cv::cvtColor(image, image, CV_BGRA2BGR);
    cv::pyrMeanShiftFiltering(image.clone(), image, 10, 10, 4);
    cv::cvtColor(image, image, CV_BGR2BGRA);
    
    assert(image.dims==2);
    assert(CV_MAT_TYPE(image.type())==CV_8UC4);
    
    
    
    /**drew's handy dandy translation guide:
     image.size.width == matrix.cols
     image.size.height == matrix.rows
     */
    printf("%d\n",sizeof(ushort));
    //if you want to grab x: 5, y: 12, channel: g, you do this one:
#define GET_PIXEL_OF_MATRIX(MTX,X,Y,CHANNEL) image.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL]
    printf("x:5,y:12,channel:g is: %d\n",GET_PIXEL_OF_MATRIX(image, 5, 12, 1));
    
    return std::vector<NotCGPoint>(); //for reasons that are sort of mysterious to me, c++ is not very forgiving about a null pointer here...
    
    
    
     
    
    
    
}