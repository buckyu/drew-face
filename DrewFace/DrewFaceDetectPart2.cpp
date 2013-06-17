//
//  DrewFaceDetectPart2.cpp
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#include "DrewFaceDetectPart2.h"
#define _USE_MATH_DEFINES
#include <math.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui_c.h>

#define GET_PIXELORIG(X,Y,Z) testimagedataOrig[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXEL(X,Y,Z) testimagedata[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD1(X,Y,Z) testimagedataMod1[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD2(X,Y,Z) testimagedataMod2[((int)WIDTH * 4 * Y) + (4 * X) + Z]
#define PIXEL_INDEX(X,Y) Y *(int)mouthImage.size.width + X

#define DELTA_ALLOWED_FOR_WHITE 100
#define THRESHOLD_WHITE_BLACK 10
#define MIN_Y_BRIGHTNESS_THRESHOLD 150
#define MAX_Y_FOR_DARK_THRESHOLD 250
#define MAX_CR_THRESHOLD_WHITETEETH 20
#define MAX_CB_THRESHOLD_WHITETEETH 10
#define EXPECT_TEETH 5
#define NUMBER_OF_LINES 10000
#define MIN_TOOTH_SIZE 20
#define MAX_TOOTH_SIZE 50
#define MIN_DARK_SIZE 1
#define MAX_DARK_SIZE 4
#define NO 0
#define YES 1

char looksWhite(uint8_t toothY, uint8_t toothCr, uint8_t toothCb,uint8_t prevToothY) {
    if (toothY < MIN_Y_BRIGHTNESS_THRESHOLD) {
        return NO;
    }
    
    if (prevToothY != -1 && abs(prevToothY - toothY) > DELTA_ALLOWED_FOR_WHITE) {
        return NO;
    }
    if (toothCr > MAX_CR_THRESHOLD_WHITETEETH) {
        return NO;
    }
    if (toothCb > MAX_CB_THRESHOLD_WHITETEETH) {
        return NO;
    }
    return YES;
}

const int HOW_MANY_BUCKETS = 50;

const float deg45 = M_PI_4;

struct CalcStruct {
    NotCGPoint pt;
    int diffCr;
};
typedef struct CalcStruct CalcStruct;

typedef struct pindex pointIndex;


/**drew's handy dandy translation guide:
 image.size.width == matrix.cols
 image.size.height == matrix.rows
 */

float *xyzOfRGB(float r, float g, float b) {
    /**
     var_R = ( R / 255 )        //R from 0 to 255
     var_G = ( G / 255 )        //G from 0 to 255
     var_B = ( B / 255 )        //B from 0 to 255
     
     if ( var_R > 0.04045 ) var_R = ( ( var_R + 0.055 ) / 1.055 ) ^ 2.4
     else                   var_R = var_R / 12.92
     if ( var_G > 0.04045 ) var_G = ( ( var_G + 0.055 ) / 1.055 ) ^ 2.4
     else                   var_G = var_G / 12.92
     if ( var_B > 0.04045 ) var_B = ( ( var_B + 0.055 ) / 1.055 ) ^ 2.4
     else                   var_B = var_B / 12.92
     
     var_R = var_R * 100
     var_G = var_G * 100
     var_B = var_B * 100
     
     //Observer. = 2°, Illuminant = D65
     X = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805
     Y = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722
     Z = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505
     */
    if(r > 0.04045) {
        r = pow((r + 0.055) / 1.055, 2.4);
    } else {
        r = r / 12.92;
    }
    if(g > 0.04045) {
        g = pow((g + 0.055) / 1.055, 2.4);
    } else {
        g = g / 12.92;
    }
    if(b > 0.04045) {
        b = pow((b + 0.055) / 1.055, 2.4);
    } else {
        b = b / 12.92;
    }
    
    r *= 100;
    g *= 100;
    b *= 100;
    
    float *ret = (float*)calloc(sizeof(float), 3);
    ret[0] = r * 0.4124 + g * 0.3576 + b * 0.1805;
    ret[1] = r * 0.2126 + g * 0.7152 + b * 0.0722;
    ret[2] = r * 0.0193 + g * 0.1192 + b * 0.9505;
    return ret;
}

float *clabOfXYZ(float *xyz) {
    /**
     var_X = X / ref_X          //ref_X =  95.047   Observer= 2°, Illuminant= D65
     var_Y = Y / ref_Y          //ref_Y = 100.000
     var_Z = Z / ref_Z          //ref_Z = 108.883
     
     if ( var_X > 0.008856 ) var_X = var_X ^ ( 1/3 )
     else                    var_X = ( 7.787 * var_X ) + ( 16 / 116 )
     if ( var_Y > 0.008856 ) var_Y = var_Y ^ ( 1/3 )
     else                    var_Y = ( 7.787 * var_Y ) + ( 16 / 116 )
     if ( var_Z > 0.008856 ) var_Z = var_Z ^ ( 1/3 )
     else                    var_Z = ( 7.787 * var_Z ) + ( 16 / 116 )
     
     CIE-L* = ( 116 * var_Y ) - 16
     CIE-a* = 500 * ( var_X - var_Y )
     CIE-b* = 200 * ( var_Y - var_Z )
     */
    float x = xyz[0] / 95.047;
    float y = xyz[1] / 100.000;
    float z = xyz[2] / 108.883;
    if(x > 0.008856) {
        x = pow(x, 1/3.0);
    } else {
        x = (7.787 * x) + (16 / 116.0);
    }
    if(y > 0.008856) {
        y = pow(y, 1/3.0);
    } else {
        y = (7.787 * y) + (16 / 116.0);
    }
    if(z > 0.008856) {
        z = pow(z, 1/3.0);
    } else {
        z = (7.787 * z) + (16 / 116.0);
    }
    
    float *ret = (float*)calloc(sizeof(float), 3);
    ret[0] = (116 * y) - 16;
    ret[1] = 500 * (x - y);
    ret[2] = 200 * (y - z);
    return ret;
}

float *cluvOfXYZ(float *xyz) {
    /**
     var_U = ( 4 * X ) / ( X + ( 15 * Y ) + ( 3 * Z ) )
     var_V = ( 9 * Y ) / ( X + ( 15 * Y ) + ( 3 * Z ) )
     
     var_Y = Y / 100
     if ( var_Y > 0.008856 ) var_Y = var_Y ^ ( 1/3 )
     else                    var_Y = ( 7.787 * var_Y ) + ( 16 / 116 )
     
     ref_X =  95.047        //Observer= 2°, Illuminant= D65
     ref_Y = 100.000
     ref_Z = 108.883
     
     ref_U = ( 4 * ref_X ) / ( ref_X + ( 15 * ref_Y ) + ( 3 * ref_Z ) )
     ref_V = ( 9 * ref_Y ) / ( ref_X + ( 15 * ref_Y ) + ( 3 * ref_Z ) )
     
     CIE-L* = ( 116 * var_Y ) - 16
     CIE-u* = 13 * CIE-L* * ( var_U - ref_U )
     CIE-v* = 13 * CIE-L* * ( var_V - ref_V )
     */
    
    float x = xyz[0];
    float y = xyz[1];
    float z = xyz[2];
    float refx = 95.047;
    float refy = 100.000;
    float refz = 108.883;
    
    float u = (4 * x) / (x + (15 * y) + (3 * z));
    float v = (9 * y) / (x + (15 * y) + (3 * z));
    y /= 100;
    if(y > 0.008856) {
        y = pow(y, 1/3.0);
    } else {
        y = (7.787 * y) + (16 / 116);
    }
    
    float refu = (4 * refx ) / (refx + (15 * refy) + (3 * refz));
    float refv = (9 * refy ) / (refx + (15 * refy) + (3 * refz));
    
    float *ret = (float*)calloc(sizeof(float), 3);
    ret[0] = ( 116 * y ) - 16;
    ret[1] = 13 * ret[0] * (u - refu);
    ret[2] = 13 * ret[0] * (v - refv);
    
    return ret;
}

#define GET_PIXEL_OF_MATRIXN(MTX, X, Y, CHANNEL, TYPE, NUM) ((MTX).at<cv::Vec<TYPE,(NUM)>>((Y),(X))[(CHANNEL)])
#define SET_PIXEL_OF_MATRIXN(MTX, X, Y, CHANNEL, TYPE, VALUE, NUM) ((MTX).at<cv::Vec<TYPE,(NUM)>>((Y),(X)))[(CHANNEL)] = (VALUE)
float rawflow(NotCGPoint top, NotCGPoint bottom,cv::Mat grad_x, cv::Mat grad_y, float angle) {
    int xcmp = sin(angle) *  GET_PIXEL_OF_MATRIXN(grad_x,top.x,top.y,0,uint8_t,3);
    int ycmp = cos(angle) * GET_PIXEL_OF_MATRIXN(grad_y,top.x,top.y,0,uint8_t,3);
    return abs(xcmp) + abs(ycmp);
}

/**This function is more or less eqn 4 from p. 3
 Automatic and Accurate Lip Tracking
 Nicolas EVENO, Alice CAPLIER, Pierre-Yves COULON
 
 Something to do with "barycentre" I'm told
 
 */
NotCGPoint reseed(int sx, int sy, std::vector<NotCGPoint> snake,cv::Mat grad) {
    float num = 0;
    float denom = 0;
    //This isn't right, but let's take an average of the Y values?
    
    for(int i = 0; i < snake.size(); i++) {
        NotCGPoint consider = snake[0];
        denom += 1;
        num += consider.y;
    }
    float newY = sy;
    if (denom > 0) { //it's possible that the whole system could have no flow, right.  in which case we should halt.
        newY = num/ denom;
        
    }
    NotCGPoint newseed;
    newseed.x = sx;
    newseed.y = newY;
    return newseed;
}
std::vector<NotCGPoint> flowFind(int sx, int sy, cv::Mat grad_x, cv::Mat grad_y, int right,const int snake_delta,float min_angle, float max_angle, int *barycentre_num, int *barycentre_denom) {
    std::vector<NotCGPoint> snake;
    
    
    //now in the R direction, we have some point
    float deg45 = M_PI_4;
    //float theta = deg45/2 - DEGREE;
    int best_flow = 0;
    
    for(float theta = min_angle; theta < max_angle; theta += .01) {
        std::vector<NotCGPoint> localSnake;
        int dx = 0;
        int dy = 0;
        //this is drawn over at §R22
        if (theta <= deg45/2 && theta >= -deg45/2) {
            //more or less horizontal, so the normal is vertical
            dy = 1;
        }
        else if (theta >= deg45/2 && theta <= deg45 + deg45/2) { //region B1
            //more or less even
            dx = 1;
            dy = 1;
        }
        else if (theta <= -deg45/2 && theta >= -deg45 - deg45/2) { //region B2
            //more or less even
            dx = 1;
            dy = 1;
        }
        else if (theta > deg45 + deg45/2 && theta <= deg45 * 2 + deg45/2) { //region C1
            //more or less vertical, so the normal is horizontal
            dx = 1;
        }
        else if (theta < -deg45 - deg45/2 && theta >= -deg45*2 - deg45/2) { //region C2
            //more or less vertical, so the normal is horizontal
            dx = 1;
        }
        else {
            abort(); //wtf
        }
        //we have some points in a line to the R point
        float flow = 0;
        float flow_in_x_dir = 0;
        float flow_in_y_dir = 0;
        for(int i = 0; i < snake_delta; i++) {
            float ix = i * cos(theta); //§R17
            float iy = i * sin(theta);
            if (right) ix *= -1;
            NotCGPoint top;
            top.x = sx + ix + dx;
            top.y = sy + iy+dy;
            
            if (abs(top.x-66)<3 && abs(top.y-41)<3) {
                int i = 0;
                printf("This will be a good solution\n");
            }
            
            
            //so the question is, what is the total flow from top to bottom
            NotCGPoint bottom;
            bottom.x = sx + ix - dx;
            bottom.y = sy + iy - dy;
            //let's not go off the reservation shall we
            if (top.x < 0 || top.y < 0 || top.x >= grad_x.cols || top.y >= grad_x.rows) break;
            
            //float flowdiff =  rawflow(top,bottom,grad_x,grad_y,theta);
            int xcmp = sin(theta) *  GET_PIXEL_OF_MATRIXN(grad_x,top.x,top.y,0,float,3);
            int ycmp = cos(theta) * GET_PIXEL_OF_MATRIXN(grad_y,top.x,top.y,0,float,3);
            flow_in_x_dir += xcmp;
            flow_in_y_dir += ycmp;
            flow += abs(xcmp) + abs(ycmp);
            localSnake.push_back(top);
            //printf("Assisting is point %d,%d with xcmp %d and ycmp %d\n",top.x,top.y,xcmp,ycmp);
        }
        
        
        printf("angle %f had flow %f composed of %f and %f\n",theta,flow,flow_in_x_dir,flow_in_y_dir);
        if (flow > best_flow) {
            *barycentre_num = flow * localSnake[0].y;
            *barycentre_denom = flow;
            snake = localSnake;
            best_flow = flow;
            
            
        }
        
    }
    assert (snake.size());
    int xcmp = GET_PIXEL_OF_MATRIXN(grad_x,snake.back().x,snake.back().y,0,float,3);
    int ycmp = GET_PIXEL_OF_MATRIXN(grad_y,snake.back().x,snake.back().y,0,float,3);
    printf("We found a solution at %d %d.  Best flow is %d\n",snake.back().x,snake.back().y,best_flow);
    return snake;
    
}
float downwardAngleCalc(int currentX, int startX) {
    /*we're being really clever with how we pick our angles here.  Essentially if we are pretty close to the center, we allow a downward slant of nearly 90 degrees.
     But near the edge, we require very near horizontal.*/
    
    return deg45/5;
    
    int distance_from_center = abs(currentX-startX);
    if (!distance_from_center) distance_from_center = 1; //avoids divide by zero
    float downward_angle = deg45*2 - distance_from_center * .01745 * 3; //there's really no rhyme or reason to this formula, it just works in practice.  accept it.
    if (downward_angle < deg45/2) downward_angle = deg45/2;
    if (downward_angle > deg45*2) downward_angle = deg45*2;
    return downward_angle;
}

std::vector<NotCGPoint>* oldAlgorithm(cv::Mat image) {
    //originally: mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //this implementation looks approximately in-place to me
    //cv::blur(myCvMat, edges, cv::Size(4,4));
	printf("finding teeth area\n");
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
#define WIDTH image.cols
#define HEIGHT image.rows
    
    
    uint8_t *testimagedataMod1 = (uint8_t*)malloc(HEIGHT * WIDTH *4);
    uint8_t *testimagedataMod2 = (uint8_t*)malloc(HEIGHT * WIDTH *4);
    memset(testimagedataMod1, 0,HEIGHT * WIDTH *4);
    memset(testimagedataMod2, 0,HEIGHT * WIDTH *4);
    
    for(int x = 0; x < WIDTH; x++) {
        for(int y = 0; y < HEIGHT; y++) {
            
            uint8_t pxR = GET_PIXEL_OF_MATRIX(image, x, y, 0);
            uint8_t pxG = GET_PIXEL_OF_MATRIX(image, x, y, 1);
            uint8_t pxB = GET_PIXEL_OF_MATRIX(image, x, y, 2);
            float Y = 0.299*(float)pxR + 0.587*(float)pxG + 0.114*(float)pxB;
            float CR = 0.713*((float)pxR - Y);
            if (CR<0) CR = 0;
            if (CR>255) CR = 255;
            float CB = 0.564*((float)pxB - Y);
            if (CB<0) CB= 0;
            if (CB>255) CB = 255;
            
            GET_PIXELMOD1(x,y,0) = Y;
            GET_PIXELMOD1(x,y,1) = CR;
            GET_PIXELMOD1(x,y,2) = CB;
            
        }
    }
    
    int MouthWidth = WIDTH;
    int MouthHeight = HEIGHT;
    int cX = MouthWidth / 2;
    
    
    for(int cY = 0; cY < MouthHeight * .5; cY += 5) {
        for(float theta = -M_PI_4 / 2; theta <= M_PI_4 / 2; theta+= 0.1) {
            for(int searchBeginPx = 0; searchBeginPx < 100; searchBeginPx++) {
                int prevToothY = -1;
                
                typedef struct {
                    int x;
                    int y;
                    int z;
                } NotCG3DPoint;
                std::vector<NotCG3DPoint> line = std::vector<NotCG3DPoint>();
                
                int prevToothCenter = searchBeginPx;
                int toothCenter = prevToothCenter + (MIN_TOOTH_SIZE);
            searchTooth:
                for(; toothCenter <= prevToothCenter + MAX_TOOTH_SIZE; toothCenter++) {
                    int tooth_notRotated_Y = 0;
                    int toothCenterX = toothCenter;
                    int toothCenterY = tooth_notRotated_Y;
                    int tooth_rotatedX = toothCenterX*cos(theta) - toothCenterY*sin(theta);
                    int tooth_rotatedY = toothCenterX * sin(theta) + toothCenterY * cos(theta) + cY; //which we rotate along some angle, §L95
                    if (tooth_rotatedX >= WIDTH || tooth_rotatedX < 0) {
                        continue;
                    }
                    if (tooth_rotatedY >= HEIGHT || tooth_rotatedY < 0) {
                        continue;
                    }
                    
                    int toothY = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 0);
                    int toothCR = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 1);
                    int toothCB = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 2);
                    
                    if (!looksWhite(toothY, toothCR, toothCB, prevToothY)) continue;
                    //now let's look for a suitable dark patch
                    
                    char found_dark = NO;
                    int dark_rotatedX_sln = -99;
                    int dark_rotatedY_sln = -99;
                    for(int darkCenter = toothCenter + MIN_TOOTH_SIZE / 2; darkCenter <= toothCenter + MAX_TOOTH_SIZE / 2; darkCenter++) {
                        int dark_notRotated_Y = tooth_notRotated_Y;
                        int dark_rotatedX = darkCenter * cos(theta) - dark_notRotated_Y * sin(theta);
                        int dark_rotatedY = darkCenter * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                        if (dark_rotatedX >= WIDTH || dark_rotatedX < 0) {
                            continue;
                        }
                        if (dark_rotatedY >= HEIGHT || dark_rotatedY < 0) {
                            continue;
                        }
                        int darkY = GET_PIXELMOD1(dark_rotatedX, dark_rotatedY, 0);
                        if (abs(toothY - darkY) < THRESHOLD_WHITE_BLACK) {
                            continue;
                        }
                        if (darkY > MAX_Y_FOR_DARK_THRESHOLD) {
                            continue;
                        }
                        //check that we've gone back to white after MAX_DARK_SIZE
                        int darkEnd = darkCenter + MAX_DARK_SIZE;
                        int dark_rotatedEndX = darkEnd * cos(theta) - dark_notRotated_Y * sin(theta);
                        int dark_rotatedEndY = darkEnd * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                        if (dark_rotatedEndY < 0 || dark_rotatedEndY >= MouthHeight) continue;
                        if (dark_rotatedEndX < 0 || dark_rotatedEndX >= MouthWidth) continue;
                        int darkEndY = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 0);
                        int darkEndCr = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 1);
                        int darkEndCb = GET_PIXELMOD1(dark_rotatedEndX, dark_rotatedEndY, 2);
                        if (!looksWhite(darkEndY, darkEndCr, darkEndCb, prevToothY)) {
                            continue;
                        }
                        
                        found_dark = YES;
                        dark_rotatedX_sln = dark_rotatedX;
                        dark_rotatedY_sln = dark_rotatedY;
                        
                    }
                    if (!found_dark) {
                        continue;
                    }
                    
                    
                    
                    
                    
                    
                    
                    NotCG3DPoint coord;
                    coord.x = tooth_rotatedX;
                    coord.y = tooth_rotatedY;
                    coord.z = 0;
                    
                    NotCG3DPoint darkCoord;
                    darkCoord.x = dark_rotatedX_sln;
                    darkCoord.y = dark_rotatedY_sln;
                    darkCoord.z = 2;
                    
                    line.push_back(coord);
                    line.push_back(darkCoord);
                    prevToothY = toothY;
                    prevToothCenter = toothCenter;
                    toothCenter = prevToothCenter + MIN_TOOTH_SIZE;
                }
                
                if (line.size() >= EXPECT_TEETH) {
                    //NSLog(@"found teeth at %@",line);
                    for(int i = 0; i < line.size(); i++) {
                        NotCG3DPoint coord = line[i];
                        GET_PIXELMOD2(coord.x, coord.y, coord.z) = 0xff;
                    }
                }
                
            }
        }
        
    }
    
    //gitftwrap
    //todo: convert this to more C
    
    
    
    std::vector<NotCGPoint> *solutionArray = new std::vector<NotCGPoint>;
    int leftmostX = -1;
    int leftmostY = -1;
    for(int x = 0; x < WIDTH; x++) {
        for(int y = 0; y < HEIGHT; y++) {
            if (GET_PIXELMOD2(x, y, 0)==0xff) {
                leftmostX = x;
                leftmostY = y;
                break;
            }
        }
        if (leftmostX != -1) break;
    }
    int pX = leftmostX;
    int pY = leftmostY;
    while(true) {
        int qX = -1;
        int qY = -1;
        //p --> q --> r
        
        qX = leftmostX;
        qY = leftmostY;
        for(int rX = 0; rX < WIDTH; rX++) {
            for(int rY = 0; rY < HEIGHT; rY++) {
                
                if (GET_PIXELMOD2(rX, rY, 0)!=0xff) continue;
#define TURN_LEFT 1
#define TURN_RIGHT -1
#define TURN_NONE 0
                
                float dist_p_r = pow(pX - rX,2) + pow(pY - rY,2);
                float dist_p_q = pow(pX - qX,2) + pow(pY - qY,2);
                //compute the turn
                int t = -999;
                int lside = (qX - pX) * (rY - pY) - (rX - pX) * (qY - pY);
                if (lside < 0) t = -1;
                if (lside > 0) t = 1;
                if (lside==0) t = 0;
                if (t==TURN_RIGHT || (t==TURN_NONE && dist_p_r > dist_p_q)) {
                    qX = rX;
                    qY = rY;
                }
            }
        }
        //we consider qX to be in our solution
        NotCGPoint soln;
        soln.x = qX;
        soln.y = qY;
        solutionArray->push_back(soln);
        if (qX == leftmostX && qY == leftmostY) {
            break;
        }
        pX = qX;
        pY = qY;
    }
    free(testimagedataMod1);
    free(testimagedataMod2);
    
    printf("solution of size %lu\n",solutionArray->size());
    
    return solutionArray;
}

cv::Mat findTeethAreaDebug(cv::Mat image) {
    cv::Mat originalImage = image.clone();
    image.convertTo(image, CV_32F);
    
    cv::Mat RGB = cvCreateMat(image.rows, image.cols, CV_32F);
    cv::cvtColor(image, RGB, CV_BGRA2BGR);
    
    cv::Mat CIELAB = RGB.clone();
    cv::cvtColor(image, CIELAB, CV_BGR2Lab);
    
    cv::Mat CIELUV = RGB.clone();
    cv::cvtColor(image, CIELUV, CV_BGR2Luv);
    
    cv::Mat HSV = RGB.clone();
    cv::cvtColor(image, HSV, CV_BGR2HSV);
    
    //R, G, B, H, S, V, L, a, b, u, v, ?
    cv::Mat_<cv::Vec<float, 12>> colorSpace(RGB.rows, RGB.cols);
    float max[3];
    float meanU = 0;
    float meanA = 0;
    for(int y = 0; y < RGB.rows; y++) {
        for(int x = 0; x < RGB.cols; x++) {
            int i = 0;
            float r = GET_PIXEL_OF_MATRIXN(RGB, x, y, 0, float, 3) / 255.0;
            float g = GET_PIXEL_OF_MATRIXN(RGB, x, y, 1, float, 3) / 255.0;
            float b = GET_PIXEL_OF_MATRIXN(RGB, x, y, 2, float, 3) / 255.0;
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, r, 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, g, 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, b, 12);
            float h = (GET_PIXEL_OF_MATRIXN(HSV, x, y, 0, float, 3) / 360.0 + 30 / 360.0);
            if(h >= 1) {
                h -= 1;
            }
            float s = GET_PIXEL_OF_MATRIXN(HSV, x, y, 1, float, 3);
            float v = GET_PIXEL_OF_MATRIXN(HSV, x, y, 2, float, 3) / 255.0;
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, h, 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, s, 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, v, 12);
            
            /*float l = GET_PIXEL_OF_MATRIXN(CIELAB, x, y, 0, float, 3);
             float a = GET_PIXEL_OF_MATRIXN(CIELAB, x, y, 1, float, 3);
             b = GET_PIXEL_OF_MATRIXN(CIELAB, x, y, 2, float, 3);
             SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, l, 12);
             SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, a, 12);
             SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, b, 12);
             SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, GET_PIXEL_OF_MATRIXN(CIELUV, x, y, 1, float, 3), 12);
             SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, GET_PIXEL_OF_MATRIXN(CIELUV, x, y, 2, float, 3), 12);*/
            
            float *xyz = xyzOfRGB(r, g, b);
            float *lab = clabOfXYZ(xyz);
            float *luv = cluvOfXYZ(xyz);
            free(xyz);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, lab[0], 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, lab[1], 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, lab[2], 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, luv[1], 12);
            SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, luv[2], 12);
            meanU += luv[1] / (RGB.rows * RGB.cols);
            meanA += lab[1] / (RGB.rows * RGB.cols);
            free(lab);
            free(luv);
            
            float denom = r + g;
            if(denom == 0) {
                SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, 0, 12);
            } else {
                SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i++, float, r / denom, 12);
            }
        }
    }
    
    //compute std
    float stdevU = 0;
    float stdevA = 0;
    for(int y = 0; y < RGB.rows; y++) {
        for(int x = 0; x < RGB.cols; x++) {
            float u = GET_PIXEL_OF_MATRIXN(colorSpace,x,y,9,float,12);
            float a = GET_PIXEL_OF_MATRIXN(colorSpace,x,y,7,float,12);
            stdevU += powf(u - meanU,2);
            stdevA += powf(a - meanA,2);
        }
    }
    stdevU = sqrtf(stdevU / (RGB.rows * RGB.cols));
    stdevA = sqrt(stdevA / (RGB.rows * RGB.cols));
    
    
    
    cv::Mat_<cv::Vec<float, 3>> Snakes(RGB.rows, RGB.cols);
    for(int y = 0; y < RGB.rows; y++) {
        for(int x = 0; x < RGB.cols; x++) {
            float L = GET_PIXEL_OF_MATRIXN(colorSpace, x, y, 6, float, 12);
            float X = GET_PIXEL_OF_MATRIXN(colorSpace, x, y, 11, float, 12);
            float R = GET_PIXEL_OF_MATRIXN(colorSpace,x,y,0,float,12);
            
            
            /**The algorithm below is given by
             INNER LIP SEGMENTATION BY COMBINING ACTIVE CONTOURS AND PARAMETRIC MODELS
             Sebastien Stillittano 1 and Alice Caplier 2
             */
            /*SET_PIXEL_OF_MATRIXN(Snakes,x,y,0,float,R*255*.33 - u/100*255*.33 - X*255*.33,3);
             SET_PIXEL_OF_MATRIXN(Snakes,x,y,1,float,R*255*.33 - u/100*255*.33 - X*255*.33,3);
             SET_PIXEL_OF_MATRIXN(Snakes,x,y,2,float,R*255*.33 - u/100*255*.33 - X*255*.33,3);*/
            
            /**The algorithm below is given by
             Automatic and Accurate Lip Tracking
             Nicolas EVENO, Alice CAPLIER, Pierre-Yves COULON
             */
            float value = 0;
            value = X * 255 * .5 - L / 100 * 255 * .5;
            SET_PIXEL_OF_MATRIXN(Snakes,x,y,0,float,value,3);
            SET_PIXEL_OF_MATRIXN(Snakes,x,y,1,float,value,3);
            SET_PIXEL_OF_MATRIXN(Snakes,x,y,2,float,value,3);
            
        }
    }
    
    
    //GaussianBlur( Snakes, Snakes, cv::Size(5,5), 0, 0, cv::BORDER_DEFAULT );
    
    
    //compute a sobel derivative
    cv::Mat grad_x, grad_y;
    cv::Mat abs_grad_x, abs_grad_y;
    cv::Mat grad;
    int ddepth = -1;
    int scale = 1;
    int delta = 0;
    
    //http://docs.opencv.org/doc/tutorials/imgproc/imgtrans/sobel_derivatives/sobel_derivatives.html
    
    /// Gradient X
    Sobel( Snakes, abs_grad_x, ddepth, 1, 0, 3, scale, delta, cv::BORDER_DEFAULT );
    //convertScaleAbs( grad_x, abs_grad_x );
    /// Gradient Y
    Sobel( Snakes, abs_grad_y, ddepth, 0, 1, 3, scale, delta, cv::BORDER_DEFAULT );
    //convertScaleAbs( grad_y, abs_grad_y );
    
    //we should probably display something
    cv::Mat scaledX;
    convertScaleAbs(abs_grad_x,scaledX);
    cv::Mat scaledY;
    convertScaleAbs(abs_grad_y,scaledY);
    
    cv::Mat gradDisplay = cvCreateMat(image.rows, image.cols, CV_8UC3);
    for(int y = 0; y < RGB.rows; y++) {
        for (int x = 0; x < RGB.cols; x++) {
            int y_px = GET_PIXEL_OF_MATRIXN(scaledY,x,y,0,uint8_t,3);
            SET_PIXEL_OF_MATRIXN(gradDisplay,x,y,1,uint8_t,y_px,3);
            int x_px = GET_PIXEL_OF_MATRIXN(scaledX,x,y,0,uint8_t,3);
            SET_PIXEL_OF_MATRIXN(gradDisplay,x,y,2,uint8_t,x_px,3);
            
        }
    }
    
    /*(for(int y = 0; y < RGB.rows; y++) {
     for(int x = 0; x < RGB.cols; x++) {
     //this method was first shown in Wang, 2004.  Sourced from INNER LIP SEGMENTATION BY COMBINING ACTIVE CONTOURS AND PARAMETRIC MODELS
     //I believe the source has an error, this is Wang's formula
     float u = GET_PIXEL_OF_MATRIXN(colorSpace,x,y,9,float,12);
     float a = GET_PIXEL_OF_MATRIXN(colorSpace,x,y,7,float,12);
     if (u <= meanU  - stdevU|| a <= meanA - stdevA) {
     SET_PIXEL_OF_MATRIXN(abs_grad_x,x,y,0,uint8_t,0,3);
     SET_PIXEL_OF_MATRIXN(abs_grad_x,x,y,1,uint8_t,0,3);
     SET_PIXEL_OF_MATRIXN(abs_grad_x,x,y,2,uint8_t,0,3);
     
     SET_PIXEL_OF_MATRIXN(abs_grad_y,x,y,0,uint8_t,0,3);
     SET_PIXEL_OF_MATRIXN(abs_grad_y,x,y,1,uint8_t,0,3);
     SET_PIXEL_OF_MATRIXN(abs_grad_y,x,y,2,uint8_t,0,3);
     
     
     }
     }
     }*/
    
    addWeighted( abs_grad_x, 0.5, abs_grad_y, 0.5, 0, grad );
    
    //first, we're going to run the old algorithm
    
    std::vector<NotCGPoint> *old_algorithm = oldAlgorithm(originalImage);
    NotCGPoint tallestPoint;
    for (int x = 0; x < old_algorithm->size(); x++) {
        if ((*old_algorithm)[x].y < tallestPoint.y) {
            tallestPoint = (*old_algorithm)[x];
        }
    }
    
    //okay, let's pick a point
    int sx = grad.cols * .5;
    int sy = tallestPoint.y;
    
    
    std::vector<NotCGPoint> snake;
    int iterations = 0;
    const int max_iterations = 15;
    while(true) {
        if (iterations >=  max_iterations) {
            break;
        }
        iterations++;
        snake.clear();
        NotCGPoint start;
        start.x = sx;
        start.y = sy;
        
        
        
        
        /**Let's begin a search to the right
         start--x--y--z */
#define APPEND(dest,src) dest.insert(dest.end(),src.begin(),src.end())
        std::vector<NotCGPoint> R;
        R.push_back(start);
        const int segment_len = 40;
        float deg45 = M_PI_4;
        const float DEGREE = 0.0174532925;
        int total_num = 0;
        int total_denom = 0;
        printf("left calc\n");
        for(int x = sx; x < image.cols; x+= segment_len) {
            int l_num = 0;
            int l_denom = 0;
            float downward_angle = downwardAngleCalc(R.back().x,start.x);
            std::vector<NotCGPoint> segment = flowFind(R.back().x, R.back().y,abs_grad_x, abs_grad_y, true, segment_len,-M_PI/6.0,M_PI/3.0,&l_num,&l_denom);
            printf("segment %d / %d \n",l_num,l_denom);
            total_num += l_num;
            total_denom += l_denom;
            APPEND(R, segment);
        }
        
        /**Now searching to the left
         a--b--c--start
         
         However, our list is processing in reverse order here
         start--c--b--a
         
         */
        std::vector<NotCGPoint> L;
        L.push_back(start);
        for(int x = sx; x > 0; x-= segment_len) {
            int l_num = 0;
            int l_denom = 0;
            float downward_angle = downwardAngleCalc(L.back().x,start.x);
            std::vector<NotCGPoint> segment = flowFind(L.back().x, L.back().y,abs_grad_x,abs_grad_y, false, segment_len,-M_PI/6.0,M_PI/3.0,&l_num,&l_denom);
            total_num+=l_num;
            total_denom += l_denom;
            
            APPEND(L, segment);
        }
        
        //convert to a-b-c-start order
        std::reverse(L.begin(),L.end());
        
        APPEND(snake, L);
        APPEND(snake, R);
        
        
        //let's go ahead and compute a new seed for fun
        NotCGPoint newseed;
        newseed.x = sx;
        if (total_denom==0) {
            newseed.y = sy;
        }
        else {
            newseed.y = 0.5 * (sy + total_num / total_denom);
        }
        printf("Recommend moving from %d,%d to %d,%d\n",sx,sy,newseed.x,newseed.y);
        //now there are two cases here.  either our newseed is close to the original one or it isn't.
        if (sqrt(powf(newseed.y-start.y, 2)+powf(newseed.x-start.x, 2)) < 2) {
            break;
#warning
        }
        /*if (true) {
         break;
         }*/
        sx = newseed.x;
        sy = newseed.y;
        
        
        
    }
    
    
    for(int i = 0; i < snake.size(); i++) {
        NotCGPoint snakePT = snake[i];
        SET_PIXEL_OF_MATRIXN(gradDisplay,snakePT.x,snakePT.y,0,uint8_t,255,3);
        
    }
    
    return gradDisplay;
    
    
    
    
    
    
    
    printf("Max l, a, b = {%f, %f, %f}\n", max[0], max[1], max[2]);
    
    const char *labels[12] = {"r", "g", "b", "h", "s", "v", "l", "a", "b", "u", "v", "?"};
    printf("Light tooth\n");
    printf("H = %f\n", GET_PIXEL_OF_MATRIXN(HSV, 122, 68, 0, float, 3));
    for(int i = 0; i < 12; i++) {
        printf("Pixel[%s] = %f\n", labels[i], GET_PIXEL_OF_MATRIXN(colorSpace, 122, 68, i, float, 12));
    }
    printf("Dark tooth\n");
    printf("H = %f\n", GET_PIXEL_OF_MATRIXN(HSV, 36, 54, 0, float, 3));
    for(int i = 0; i < 12; i++) {
        printf("Pixel[%s] = %f\n", labels[i], GET_PIXEL_OF_MATRIXN(colorSpace, 36, 54, i, float, 12));
    }
    printf("Lip\n");
    printf("H = %f\n", GET_PIXEL_OF_MATRIXN(HSV, 127, 50, 0, float, 3));
    for(int i = 0; i < 12; i++) {
        printf("Pixel[%s] = %f\n", labels[i], GET_PIXEL_OF_MATRIXN(colorSpace, 127, 50, i, float, 12));
    }
    printf("Max H\n");
    printf("H = %f\n", GET_PIXEL_OF_MATRIXN(HSV, 5, 45, 0, float, 3));
    for(int i = 0; i < 12; i++) {
        printf("Pixel[%s] = %f\n", labels[i], GET_PIXEL_OF_MATRIXN(colorSpace, 5, 45, i, float, 12));
    }
    
    // a' = (a - mu) / aleph
    // a'' = a' * m
    // a'' = (a - mu) * m / aleph
    float mu[12];
    int i = 0;
    mu[i++] = .5676;
    mu[i++] = .4568;
    mu[i++] = .4427;
    mu[i++] = .4044;
    mu[i++] = .2650;
    mu[i++] = .5718;
    mu[i++] = 51.2836;
    mu[i++] = 11.2164;
    mu[i++] = 6.6904;
    mu[i++] = .2410;
    mu[i++] = .4951;
    mu[i++] = .5600;
    i = 0;
    float aleph[12];
    aleph[i++] = .1982;
    aleph[i++] = .1861;
    aleph[i++] = .1837;
    aleph[i++] = .4200;
    aleph[i++] = .1269;
    aleph[i++] = .2008;
    aleph[i++] = 18.6664;
    aleph[i++] = 9.4382;
    aleph[i++] = 7.5667;
    aleph[i++] = 0.0246;
    aleph[i++] = .0119;
    aleph[i++] = .0456;
    float m[12];
    i = 0;
    m[i++] = 16.2401;
    m[i++] = -10.6024;
    m[i++] = -1.1409;
    m[i++] = -.0264;
    m[i++] = -.513;
    m[i++] = .475;
    m[i++] = -3.98;
    m[i++] = -8.4148;
    m[i++] = -1.2962;
    m[i++] = 6.2434;
    m[i++] = -1.0480;
    m[i++] = -4.6361;
    float m2[12];
    i = 0;
    m2[i++] = -14.9876;
    m2[i++] = 30.9664;
    m2[i++] = -16.7017;
    m2[i++] = .1505;
    m2[i++] = -1.0330;
    m2[i++] = 4.6850;
    m2[i++] = -4.6476;
    m2[i++] = 9.5569;
    m2[i++] = -4.8199;
    m2[i++] = -2.3136;
    m2[i++] = 2.1365;
    m2[i++] = 1.7660;
    
    for(int y = 0; y < RGB.rows; y++) {
        for(int x = 0; x < RGB.cols; x++) {
            for(int i = 0; i < 12; i++) {
                SET_PIXEL_OF_MATRIXN(colorSpace, x, y, i, float, (GET_PIXEL_OF_MATRIXN(colorSpace, x, y, i, float, 12) - mu[i]) * m[i] / aleph[i], 12);
            }
        }
    }
    
    cv::Mat_<uint8_t> membership(RGB.rows, RGB.cols);
    
#define NUM_CLUSTERS 2
    cv::Vec<double, 12> means[NUM_CLUSTERS];
    for(int i = 0; i < 12; i++) {
        means[0][i] = (0 - mu[i]) * m[i] / aleph[i];
    }
    for(int i = 0; i < 12; i++) {
        means[1][i] = (0 - mu[i]) * m2[i] / aleph[i];
    }
    
    while(true) {
        //assign pixels to clusters based on euclidean distance
        for(int y = 0; y < RGB.rows; y++) {
            for(int x = 0; x < RGB.cols; x++) {
                uint8_t minCluster = -1;
                double minClusterDist = MAXFLOAT;
                for(uint8_t cluster = 0; cluster < NUM_CLUSTERS; cluster++) {
                    double subtotal = 0;
                    for(int i = 0; i < 12; i++) {
                        subtotal += pow(means[cluster][i] - GET_PIXEL_OF_MATRIXN(colorSpace, x, y, i, float, 12), 2);
                    }
                    double dist = sqrt(subtotal);
                    if(dist < minClusterDist) {
                        minCluster = cluster;
                        minClusterDist = dist;
                    }
                    assert(minCluster >= 0 && minCluster < NUM_CLUSTERS);
                    assert(minClusterDist >= 0);
                }
                assert(minCluster >= 0 && minCluster < NUM_CLUSTERS);
                membership.at<uint8_t>(y, x) = minCluster;
            }
        }
        
        //recompute means for clusters
        for(int i = 0; i < NUM_CLUSTERS; i++) {
            for(int j = 0; j < 12; j++) {
                means[i][j] = 0;
            }
        }
        for(int y = 0; y < RGB.rows; y++) {
            for(int x = 0; x < RGB.cols; x++) {
                uint8_t group = membership.at<uint8_t>(y, x);
                for(int i = 0; i < 12; i++) {
                    means[group][i] += GET_PIXEL_OF_MATRIXN(colorSpace, x, y, i, float, 12) / (double)(RGB.rows * RGB.cols);
                }
            }
        }
        
        //TODO: break for some reason
        break;
    }
    
    cv::Mat ret = RGB.clone();
    for(int y = 0; y < ret.rows; y++) {
        for(int x = 0; x < ret.cols; x++) {
            uint8_t group = membership.at<uint8_t>(y, x);
            uint8_t color = (group == 1)?0:255;
            for(int i = 0; i < 3; i++) {
                SET_PIXEL_OF_MATRIXN(ret, x, y, i, float, color, 3);
            }
        }
    }
    
    return ret;
}




std::vector<NotCGPoint>* findTeethArea(cv::Mat image) {
    return new std::vector<NotCGPoint>();
    
}