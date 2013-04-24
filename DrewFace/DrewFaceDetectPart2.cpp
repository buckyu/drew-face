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

const int HOW_MANY_BUCKETS = 50;

struct CalcStruct {
    NotCGPoint pt;
    int diffCr;
};
typedef struct CalcStruct CalcStruct;

struct pindex {
    NotCGPoint first;
    int second;
    /**I continue to be sorry*/
    pindex(NotCGPoint ifirst,int isecond) {
        this->first = ifirst;
        this->second = isecond;
    }
    pindex() {
        
    }
    bool operator<( const pindex & n ) const {
        //compute hash
        int hash = this->first.x * 100000 + this->first.y * 10000 + this->second;
        int hash2 = n.first.x * 100000 + n.first.y * 10000 + n.second;
        return hash < hash2;   // for example
    }
    bool operator==( const pindex & n) const {
        return this->first.x==n.first.x && this->first.y == n.first.y && this->second==n.second;
    }

};
typedef struct pindex pointIndex;


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

std::vector<std::vector<CalcStruct>*> *bionsCalc(cv::Mat image) {
    assert(image.dims==2);
    assert(CV_MAT_TYPE(image.type())==CV_8UC4);
    
    /**drew's handy dandy translation guide:
     image.size.width == matrix.cols
     image.size.height == matrix.rows
     */
    printf("%ld\n",sizeof(ushort));
    //if you want to grab x: 5, y: 12, channel: g, you do this one:
#define GET_PIXEL_OF_MATRIX(MTX,X,Y,CHANNEL) image.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL]
#define SET_PIXEL_OF_MATRIX(MTX,X,Y,CHANNEL,VALUE) image.at<cv::Vec<uint8_t,4>>(Y,X)[CHANNEL] = VALUE
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
    
    printf("hi!");
#define SLICE_FOR_NUM_SLICES(num) (M_PI_4 / (num / 8))
#define COLOR_THRESHOLD 20
#define MIN_POINTS_PER_VECTOR 8
    //std::vector<NotCGPoint> *solutionArray = new std::vector<NotCGPoint>;
    std::vector<std::vector<CalcStruct>*> *vectors = new std::vector<std::vector<CalcStruct>*>;
    int cX = WIDTH / 2;
    int cY = HEIGHT / 2;
    for(float theta = 0; theta <= 2 * M_PI; theta += SLICE_FOR_NUM_SLICES(1024)) {
        int colorThreshold = COLOR_THRESHOLD;
    radius_loop:
        int transitionCount = 0;
        int baseY = GET_PIXELMOD1(cX, cY, 0);
        int baseCr = GET_PIXELMOD1(cX, cY, 1);
        int baseCb = GET_PIXELMOD1(cX, cY, 2);
        std::vector<CalcStruct> *transitions = new std::vector<CalcStruct>;
        for(float r = 0; r <= WIDTH / 2; r += 0.5) {
            int x = (int)roundf(cX + r * cos(theta));
            int y = (int)roundf(cY + r * sin(theta));
            if(x < 0 || y < 0 || x >= WIDTH || y >= HEIGHT) {
                break;
            }
            
            int testY = GET_PIXELMOD1(x, y, 0);
            int testCr = GET_PIXELMOD1(x, y, 1);
            int testCb = GET_PIXELMOD1(x, y, 2);
            
            int diffY = abs(testY - baseY);
            int diffCr = abs(testCr - baseCr);
            int diffCb = abs(testCb - baseCb);
            
            if(diffCr > colorThreshold) {
                //GET_PIXELMOD2(x, y, 0) = 0xff;
                CalcStruct pt = {.pt={.x=x, .y=y}, .diffCr=diffCr};
                transitions->push_back(pt);
                transitionCount++;
                //solutionArray->push_back(pt);
                baseY = testY;
                baseCr = testCr;
                baseCb = testCb;
            }
        }
        if(transitionCount < MIN_POINTS_PER_VECTOR && 0) {
            if(colorThreshold == 0) {
                fprintf(stderr, "There is no red shift anywhere along this angle. Your image just sucks.\n");
                assert(!vectors->empty());
                return new std::vector<std::vector<CalcStruct>*>;
            }
            colorThreshold--;
            goto radius_loop;
        }
        vectors->push_back(transitions);
    }
    
    for(int i = 0; i < vectors->at(i)->size(); i++) {
        for(int y = 0; y < vectors->at(i)->size(); y++) {
            NotCGPoint debug = vectors->at(i)->at(y).pt;
            SET_PIXEL_OF_MATRIX(image, debug.x, debug.y, 0,0xff);
            SET_PIXEL_OF_MATRIX(image, debug.x, debug.y, 1,0xff);
        }
    }
    free(testimagedataMod1);
    free(testimagedataMod2);
    
    return vectors;
    
}

cv::Mat findTeethAreaDebug(cv::Mat image) {
    cv::cvtColor(image, image, CV_BGRA2BGR);
    cv::pyrMeanShiftFiltering(image.clone(), image, 20, 20, 4);
    cv::cvtColor(image, image, CV_BGR2BGRA);
    std::vector<std::vector<CalcStruct> *> *vectors = bionsCalc(image);

    return image;
}

float heuristic(pointIndex where, std::vector<CalcStruct> goals) {
    NotCGPoint stupid = goals[0].pt;
    return HOW_MANY_BUCKETS - where.second;
}

float heuristic2(NotCGPoint from, CalcStruct to, NotCGPoint centerPt) {
    float weighted_diffcr = 1/ (to.diffCr / 0.3);
    float horizontal_is_good = 1 / (fabsf(from.x - to.pt.x) + 1) * 5;
    //printf("adjusted diffcf %f\n",weighted_diffcr);
    //if (from.x==to.pt.x && from.y==to.pt.y) return 2;
    float euclid = sqrtf(powf(from.y - to.pt.y, 2) + powf(from.x - to.pt.x, 2));
    return weighted_diffcr + euclid + horizontal_is_good+  1;
    //the cost is the inverse of the distance from the center? (e.g. find the outermost point such that)

    //return abs(from.y - to.y) + 1.0 / (sqrtf(powf(centerPt.y - to.y, 2) + pow(centerPt.x - to.x, 2)));
}

std::vector<pointIndex> *reconstruct_path(std::map<pointIndex,pointIndex> *came_from, pointIndex current_node) {
    if (came_from->count(current_node)) {
        pointIndex a = came_from->at(current_node);
        assert(a.second==current_node.second - 1);
        std::vector<pointIndex> *path = reconstruct_path(came_from, came_from->at(current_node));
        path->insert(path->begin(), current_node);
        return path;
    }
    std::vector<pointIndex> *newPath = new std::vector<pointIndex>;
    newPath->push_back(current_node);
    return newPath;
}

std::vector<NotCGPoint>* findTeethArea(cv::Mat image) {
    //originally: mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //this implementation looks approximately in-place to me
    //cv::blur(myCvMat, edges, cv::Size(4,4));
	printf("finding teeth area\n");
    image = findTeethAreaDebug(image);
    
    std::vector<std::vector<CalcStruct> *> *vectors = bionsCalc(image);
    
    //scale down to 100 results
    std::vector<std::vector<CalcStruct> *> *scaled = new std::vector<std::vector<CalcStruct> *>;
    int bucket = 0;
    std::vector<CalcStruct> *bucketV = new std::vector<CalcStruct>;

    for(int i = 0; i < vectors->size(); i++) {
        for(int y = 0; y < vectors->at(i)->size(); y++) {
            bucketV->push_back(vectors->at(i)->at(y));
        }
        bucket++;
        if (bucketV->size() && bucket >  HOW_MANY_BUCKETS / bucketV->size()) {
            printf("bucket of size %d\n",bucketV->size());
            scaled->push_back(bucketV);
            bucketV = new std::vector<CalcStruct>;
            bucket = 0;
        }
    }
    printf("total buckets %d\n",scaled->size());
    vectors = scaled;
    
    std::vector<pointIndex> *closedSet = new std::vector<pointIndex>;
    std::vector<pointIndex> *openSet = new std::vector<pointIndex>;
    std::map<pointIndex,pointIndex> *came_from = new std::map<pointIndex,pointIndex>();
    typedef std::pair<pointIndex,pointIndex> pointToPoint;
    std::map<pointIndex,float> *g = new std::map<pointIndex,float>;
    typedef std::pair<pointIndex,float> score;
    std::map<pointIndex,float> *f = new std::map<pointIndex,float>;
    //typedef std::pair<pointIndex,int> pointIndex;
    if (!vectors->size()) {
        printf("bion gave us no solution, you're not getting one either\n");
        return new std::vector<NotCGPoint>;
    }
    std::vector<CalcStruct> *goals = vectors->at(vectors->size() - 1);
    for (int i = 0; i < vectors->at(0)->size(); i++) {
        NotCGPoint node = vectors->at(0)->at(i).pt;
        openSet->push_back(pointIndex(node,0));
        g->insert(score(pointIndex(node,0),0));
        f->insert(score(pointIndex(node,0),heuristic(pointIndex(node,vectors->size()), *goals)));
        printf("start node %d,%d at position %d\n",node.x,node.y,vectors->size());
    }
    while (openSet->size()) {
        pointIndex current;
        float low_f = 999999999;
        int currentOSIndex = -1;
        for(int i = 0; i < openSet->size(); i++) {
            pointIndex test = openSet->at(i);
            float test_f = f->at(test);
            if (test_f < low_f) {
                low_f = test_f;
                current = test;
                currentOSIndex = i;
            }
        }
        printf("visiting node %d,%d\n",current.first.x,current.first.y);
        //if(g->at(current) > 10 && std::find(goals->begin(), goals->end(), current.first) != goals->end()) {
        if (current.second==vectors->size()-1) { 
            std::vector<pointIndex> *solution = reconstruct_path(came_from, current);
            printf("solution of size %d\n",solution->size());
            std::vector<NotCGPoint> *actualSolution = new std::vector<NotCGPoint>;
            for(int i = 0; i < solution->size(); i++) {
                actualSolution->push_back(solution->at(i).first);
            }
            return actualSolution;
        }
        openSet->erase(openSet->begin() + currentOSIndex);
        closedSet->push_back(current);
        int nextIndex = current.second + 1;
        printf("the next index is %d\n",nextIndex);
        
        std::vector<CalcStruct> *next = vectors->at(nextIndex);
        for(int i = 0; i < next->size(); i++) {
            NotCGPoint neighbor = next->at(i).pt;
            pointIndex neighborPointIndex = pointIndex(neighbor,nextIndex);
            NotCGPoint centerPt;
            int MouthWidth = WIDTH;
            int MouthHeight = HEIGHT;

            centerPt.x = MouthWidth / 2;
            centerPt.y = MouthHeight / 2;
            float tentative_g_score = g->at(current) + heuristic2(current.first, next->at(i),centerPt);
            if(std::find(closedSet->begin(), closedSet->end(), neighborPointIndex) != closedSet->end()) {
                if (tentative_g_score >= g->at(neighborPointIndex)) {
                    continue;
                }
            }
            if (std::find(openSet->begin(), openSet->end(), neighborPointIndex)==openSet->end() || tentative_g_score < g->at(neighborPointIndex)) {
                if (neighborPointIndex.second != current.second + 1) {
                    printf("what\n");
                    abort();
                }
                (*came_from)[neighborPointIndex]=current;
                (*g)[neighborPointIndex] = tentative_g_score; //(score(neighborPointIndex,tentative_g_score));
                (*f)[neighborPointIndex] = g->at(neighborPointIndex) + heuristic(neighborPointIndex, *goals);
                //f->insert(score(neighborPointIndex,g->at(neighborPointIndex) + heuristic(neighbor, *goals)));
                if (std::find(openSet->begin(), openSet->end(), neighborPointIndex)==openSet->end()) {
                    openSet->push_back(neighborPointIndex);
                    printf("scheduling %d,%d for visit\n",neighbor.x,neighbor.y);
                }
                
            }
            else {
                printf("not considering node %d,%d because not open or poor score\n",neighbor.x,neighbor.y);
            }
        }
    }
    printf("no solution??\n");
    return new std::vector<NotCGPoint>;
    
    for(int i = 0; i < vectors->size(); i++) {
        std::vector<NotCGPoint> *transitions = new std::vector<NotCGPoint>;
        //while
        
    }


    
    return new std::vector<NotCGPoint>;
    
    
}