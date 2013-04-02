//
//  FindMouthsViewController+CPlusPlusExtensions.m
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FindMouthsViewController+CPlusPlusExtensions.h"
#import "DrewFaceDetectPart2.h"
@implementation FindMouthsViewController (CPlusPlusExtensions)

#define GET_PIXELORIG(X,Y,Z) testimagedataOrig[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXEL(X,Y,Z) testimagedata[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD1(X,Y,Z) testimagedataMod1[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD2(X,Y,Z) testimagedataMod2[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
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



// Drew's Algorithm to go here:
-(UIImage *)lookForTeethInMouthImage:(UIImage*)mouthImage {
    
    
    ocv = [OpenCvClass new];
    cv::Mat mouthImageMatrix = [ocv cvMatFromUIImage:mouthImage];
    findTeethArea(mouthImageMatrix);

    mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //mouthImage = [ocv colorTheImage:mouthImage];
    
    
    
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(mouthImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedataOrig = CFDataGetBytePtr(pixelData);
    
    
    uint8_t *testimagedata = (uint8_t*)malloc(mouthImage.size.height * mouthImage.size.width *4);
    uint8_t *testimagedataMod1 = (uint8_t*)malloc(mouthImage.size.height * mouthImage.size.width *4);
    uint8_t *testimagedataMod2 = (uint8_t*)malloc(mouthImage.size.height * mouthImage.size.width *4);
    memcpy(testimagedata, testimagedataOrig, mouthImage.size.height * mouthImage.size.width *4);
    bzero(testimagedataMod1, mouthImage.size.height * mouthImage.size.width *4);
    bzero(testimagedataMod2, mouthImage.size.height * mouthImage.size.width *4);
    
    uint8_t *zeroArray = (uint8_t*)malloc(mouthImage.size.height * mouthImage.size.width);
    bzero(zeroArray, mouthImage.size.height * mouthImage.size.width);
    
    
    for(int x = 0; x < mouthImage.size.width; x++) {
        for(int y = 0; y < mouthImage.size.height; y++) {
            
            uint8_t pxR = GET_PIXEL((x), (y), 0);
            uint8_t pxG = GET_PIXEL((x), (y), 1);
            uint8_t pxB = GET_PIXEL((x), (y), 2);
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
    
    
    
    
    
    
    
    int MouthWidth = mouthImage.size.width;
    int MouthHeight = mouthImage.size.height;
    int cX = MouthWidth / 2;
    
    
    for(int cY = 0; cY < MouthHeight * .5; cY += 5) {
        for(float theta = -M_PI_4 / 2; theta <= M_PI_4 / 2; theta+= 0.1) {
            for(int searchBeginPx = 0; searchBeginPx < 100; searchBeginPx++) {
                @autoreleasepool {
                    int prevToothY = -1;
                    NSMutableArray *line = [[NSMutableArray alloc] init];
                    int prevToothCenter = searchBeginPx;
                    int toothCenter = prevToothCenter + (MIN_TOOTH_SIZE);
                searchTooth:
                    for(; toothCenter <= prevToothCenter + MAX_TOOTH_SIZE; toothCenter++) {
                        int tooth_notRotated_Y = 0;
                        int toothCenterX = toothCenter;
                        int toothCenterY = tooth_notRotated_Y;
                        int tooth_rotatedX = toothCenterX*cos(theta) - toothCenterY*sin(theta);
                        int tooth_rotatedY = toothCenterX * sin(theta) + toothCenterY * cos(theta) + cY; //which we rotate along some angle, §L95
                        if (tooth_rotatedX >= mouthImage.size.width || tooth_rotatedX < 0) {
                            continue;
                        }
                        if (tooth_rotatedY >= mouthImage.size.height || tooth_rotatedY < 0) {
                            continue;
                        }
                        
                        int toothY = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 0);
                        int toothCR = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 1);
                        int toothCB = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 2);
                        
                        if (!looksWhite(toothY, toothCR, toothCB, prevToothY)) continue;
                        //now let's look for a suitable dark patch
                        BOOL found_dark = NO;
                        int dark_rotatedX_sln = -99;
                        int dark_rotatedY_sln = -99;
                        for(int darkCenter = toothCenter + MIN_TOOTH_SIZE / 2; darkCenter <= toothCenter + MAX_TOOTH_SIZE / 2; darkCenter++) {
                            int dark_notRotated_Y = tooth_notRotated_Y;
                            int dark_rotatedX = darkCenter * cos(theta) - dark_notRotated_Y * sin(theta);
                            int dark_rotatedY = darkCenter * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                            if (dark_rotatedX >= mouthImage.size.width || dark_rotatedX < 0) {
                                continue;
                            }
                            if (dark_rotatedY >= mouthImage.size.height || dark_rotatedY < 0) {
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
                        
                        
                        
                        
                        
                        
                        
                        
                        NSArray *coord = [[NSArray alloc] initWithObjects:@(tooth_rotatedX),@(tooth_rotatedY),@(0), nil];
                        NSArray *darkCoord = [[NSArray alloc] initWithObjects:@(dark_rotatedX_sln),@(dark_rotatedY_sln),@(2), nil];
                        [line addObject:coord];
                        [line addObject:darkCoord];
                        prevToothY = toothY;
                        prevToothCenter = toothCenter;
                        toothCenter = prevToothCenter + MIN_TOOTH_SIZE;
                    }
                    
                    if (line.count >= EXPECT_TEETH) {
                        //NSLog(@"found teeth at %@",line);
                        for(NSArray *coord in line) {
                            GET_PIXELMOD2([coord[0] intValue], [coord[1] intValue], [coord[2] intValue]) = 0xff;
                        }
                    }
                    
                }
            }
            
        }
    }
    
    
    /*
     //int YA = GET_PIXELMOD1(xa,ya,0);
     int Y0 = GET_PIXELMOD1(x0,y0,0);
     int Y1 = GET_PIXELMOD1(x1,y1,0);
     int Y2 = GET_PIXELMOD1(x2,y2,0);
     int Y3 = GET_PIXELMOD1(x3,y3,0);
     int Y4 = GET_PIXELMOD1(x4,y4,0);
     //int YB = GET_PIXELMOD1(xb,yb,0);
     
     int CR0 = GET_PIXELMOD1(x0,y0,1);
     int CR2 = GET_PIXELMOD1(x2,y2,1);
     int CR4 = GET_PIXELMOD1(x4,y4,1);
     
     int CB0 = GET_PIXELMOD1(x0,y0,2);
     int CB2 = GET_PIXELMOD1(x2,y2,2);
     int CB4 = GET_PIXELMOD1(x4,y4,2);
     
     
     
     BOOL isThreeTeethAndTwoLines = YES;
     
     
     
     if (abs(Y2-Y0) > DELTA_ALLOWED_FOR_WHITE) {
     isThreeTeethAndTwoLines = NO;
     } else if (abs(Y2-Y4) > DELTA_ALLOWED_FOR_WHITE) {
     isThreeTeethAndTwoLines = NO;
     } else if (abs(Y2-Y1) < THRESHOLD_WHITE_BLACK) {
     isThreeTeethAndTwoLines = NO;
     } else if (abs(Y2-Y3) < THRESHOLD_WHITE_BLACK) {
     isThreeTeethAndTwoLines = NO;
     }
     
     if (Y2<MIN_Y_BRIGHTNESS_THRESHOLD) {
     isThreeTeethAndTwoLines = NO;
     }
     
     if ((CR0>MAX_CR_THRESHOLD_WHITETEETH) || (CR2>MAX_CR_THRESHOLD_WHITETEETH) || (CR4>MAX_CR_THRESHOLD_WHITETEETH)) {
     isThreeTeethAndTwoLines = NO;
     }
     if ((CB0>MAX_CB_THRESHOLD_WHITETEETH) || (CB2>MAX_CB_THRESHOLD_WHITETEETH) || (CB4>MAX_CB_THRESHOLD_WHITETEETH)) {
     isThreeTeethAndTwoLines = NO;
     }
     
     //let's check the actual pixel colors
     if (GET_PIXEL(x1,y1,0)==GET_PIXEL(x2, y2, 0) && GET_PIXEL(x1,y1,1)==GET_PIXEL(x2, y2, 1) && GET_PIXEL(x1,y1,2)==GET_PIXEL(x2, y2, 2)) {
     assert(!isThreeTeethAndTwoLines);
     }
     
     
     
     // draw yellow if we are on three teeth separated by two dark lines
     if (isThreeTeethAndTwoLines) {
     
     GET_PIXELMOD2(xa,ya,0) = 0xff;
     GET_PIXELMOD2(xa,ya,1) = 0xff;
     GET_PIXELMOD2(xa,ya,2) = 0x00;
     GET_PIXELMOD2(x0,y0,0) = 0xff;
     GET_PIXELMOD2(x0,y0,1) = 0xff;
     GET_PIXELMOD2(x0,y0,2) = 0x00;
     GET_PIXELMOD2(x1,y1,0) = 0xff;
     GET_PIXELMOD2(x1,y1,1) = 0xff;
     GET_PIXELMOD2(x1,y1,2) = 0x00;
     GET_PIXELMOD2(x2,y2,0) = 0xff;
     GET_PIXELMOD2(x2,y2,1) = 0xff;
     GET_PIXELMOD2(x2,y2,2) = 0x00;
     GET_PIXELMOD2(x3,y3,0) = 0xff;
     GET_PIXELMOD2(x3,y3,1) = 0xff;
     GET_PIXELMOD2(x3,y3,2) = 0x00;
     GET_PIXELMOD2(xb,yb,0) = 0xff;
     GET_PIXELMOD2(xb,yb,1) = 0xff;
     GET_PIXELMOD2(xb,yb,2) = 0x00;
     
     }
     
     
     
     }*/
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // white dark white dark white
    // 0.25 to 0.50 width
    // X from 0 to 0.5 width
    // Y from 0 to mouthImage.size.height
    
    
    
    
    
    
    
    /*
     for(int x = 3; x < mouthImage.size.width-3; x++) {
     for(int y = 3; y < mouthImage.size.height-3; y++) {
     
     uint8_t pxB1 = GET_PIXELMOD1(x,(y-1),2);
     uint8_t pxB2 = GET_PIXELMOD1(x,(y+0),2);
     uint8_t pxB3 = GET_PIXELMOD1(x,(y+1),2);
     
     
     if ((pxB1>0) && (pxB2>0) && (pxB3>0)) {
     
     GET_PIXELMOD2(x,(y-1),0) = 0xff;
     GET_PIXELMOD2(x,(y-1),1) = 0xff;
     GET_PIXELMOD2(x,(y-1),2) = 0x00;
     
     GET_PIXELMOD2(x,(y+0),0) = 0xff;
     GET_PIXELMOD2(x,(y+0),1) = 0xff;
     GET_PIXELMOD2(x,(y+0),2) = 0x00;
     
     GET_PIXELMOD2(x,(y+1),0) = 0xff;
     GET_PIXELMOD2(x,(y+1),1) = 0xff;
     GET_PIXELMOD2(x,(y+1),2) = 0x00;
     
     
     
     }
     
     }
     }
     */
    
    
    //bzero(testimagedataMod1, mouthImage.size.width*mouthImage.size.height*4);
    
    /*
     for(int x = 3; x < mouthImage.size.width-3; x++) {
     for(int y = 3; y < mouthImage.size.height-3; y++) {
     
     
     // YUV filtering here for bright white first as interrupt
     uint8_t pxR = GET_PIXELORIG(x, y, 0);
     uint8_t pxG = GET_PIXELORIG(x, y, 1);
     uint8_t pxB = GET_PIXELORIG(x, y, 2);
     float Y = 0.299*(float)pxR + 0.587*(float)pxG + 0.114*(float)pxB;
     float CR = 0.713*((float)pxR - Y);
     float CB = 0.564*((float)pxB - Y);
     
     if ((CR<12.0) && (CB<5.0) && (Y>50)) {
     GET_PIXELMOD1(x,y,0) = 0xff;
     GET_PIXELMOD1(x,y,1) = 0x00;
     GET_PIXELMOD1(x,y,2) = 0xff;
     }
     
     }
     }
     
     */
    
    
    /*
     
     // Merge mod1 and mod2 arrays
     for(int x = 3; x < mouthImage.size.width-3; x++) {
     for(int y = 3; y < mouthImage.size.height-3; y++) {
     
     uint8_t blue0 = GET_PIXELMOD1((x-1),(y-1),2);
     uint8_t blue1 = GET_PIXELMOD1((x-0),(y-1),2);
     uint8_t blue2 = GET_PIXELMOD1((x+1),(y-1),2);
     uint8_t blue3 = GET_PIXELMOD1((x-1),(y+0),2);
     uint8_t blue4 = GET_PIXELMOD1((x+0),(y+0),2);
     uint8_t blue5 = GET_PIXELMOD1((x+1),(y+0),2);
     uint8_t blue6 = GET_PIXELMOD1((x-1),(y+1),2);
     uint8_t blue7 = GET_PIXELMOD1((x+0),(y+1),2);
     uint8_t blue8 = GET_PIXELMOD1((x+1),(y+1),2);
     
     if (blue0) blue0 = 1;
     if (blue1) blue1 = 1;
     if (blue2) blue2 = 1;
     if (blue3) blue3 = 1;
     if (blue4) blue4 = 1;
     if (blue5) blue5 = 1;
     if (blue6) blue6 = 1;
     if (blue7) blue7 = 1;
     if (blue8) blue8 = 1;
     
     
     
     if ((blue0+blue1+blue2+blue3+blue4+blue5+blue6+blue7+blue8) >= 4) {
     
     
     } else {
     
     GET_PIXELMOD2(x,(y+0),0) = 0x00;
     GET_PIXELMOD2(x,(y+0),1) = 0x00;
     GET_PIXELMOD2(x,(y+0),2) = 0x00;
     }
     
     
     }
     }
     */
    
    /*
     CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(mouthImage.CGImage);
     CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(mouthImage.CGImage);
     CGContextRef newContextRef = CGBitmapContextCreate(testimagedataMod2, mouthImage.size.width, mouthImage.size.height, 8, mouthImage.size.width*4,colorspaceRef, bitmapInfo);
     CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
     
     UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
     CGImageRelease(newImageRef);
     CGContextRelease(newContextRef);
     
     CFRelease(pixelData);
     
     free(testimagedata);
     free(testimagedataMod1);
     free(testimagedataMod2);
     free(zeroArray);
     return modifiedImage; */
    
    
    
    
    
    //gitftwrap
    //todo: convert this to more C
    
    
    
    NSMutableArray *solutionArray = [[NSMutableArray alloc] init];
    int leftmostX = -1;
    int leftmostY = -1;
    for(int x = 0; x < mouthImage.size.width; x++) {
        for(int y = 0; y < mouthImage.size.height; y++) {
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
        for(int rX = 0; rX < mouthImage.size.width; rX++) {
            for(int rY = 0; rY < mouthImage.size.height; rY++) {
                
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
        [solutionArray addObject:@[@(qX),@(qY)]];
        if (qX == leftmostX && qY == leftmostY) {
            break;
        }
        pX = qX;
        pY = qY;
    }
    
    
    
    
    
    //zero approximation - find all the pixels that look white
    /*const int zero_threshold = 50;
     for(int x = 0; x < mouthImage.size.width; x++) {
     for(int y = 0; y < mouthImage.size.height; y++) {
     float euclid = 0;
     for(int z = 0; z < 3; z++) {
     int ideal = UINT8_MAX; //convert to 16-bit signed
     int known = (int) GET_PIXEL(x, y, z);
     euclid += sqrt(pow((ideal - known),2));
     }
     if (euclid < zero_threshold) {
     zeroArray[PIXEL_INDEX(x,y)] = 1;
     }
     }
     }*/
    
    
    //draw on top of the image, this is purely for debugging
    __block UIImage *outImage;
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContext(mouthImage.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, 0.0, mouthImage.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGRect rect1 = CGRectMake(0, 0, mouthImage.size.width, mouthImage.size.height);
        CGContextDrawImage(context, rect1, mouthImage.CGImage);
        
        UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
        CGContextSetFillColorWithColor(context, color.CGColor);
        for(int x = 1; x < mouthImage.size.width-1; x++) {
            
            for(int y = 1; y < mouthImage.size.height-1; y++) {
                if (zeroArray[PIXEL_INDEX(x,y)]) {
                    CGContextFillRect(context, CGRectMake(x-1, mouthImage.size.height-(y-1), -2, -2));
                    
                }
            }
        }
        outImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    
    // show image on iPhone view
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(mouthImage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(mouthImage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(testimagedata, mouthImage.size.width, mouthImage.size.height, 8, mouthImage.size.width*4,colorspaceRef, bitmapInfo);
    UIColor *greenColor = [UIColor greenColor];
    CGContextSetStrokeColorWithColor(newContextRef, greenColor.CGColor);
    CGContextSetLineWidth(newContextRef, 3.0);
    CGContextScaleCTM(newContextRef, 1.0, -1.0);
    CGContextTranslateCTM(newContextRef, 0.0, -mouthImage.size.height);
    CGMutablePathRef myRef = CGPathCreateMutable();
    CGPathMoveToPoint(myRef, NULL, leftmostX, leftmostY);
    for (NSArray *pt in solutionArray) {
        CGPathAddLineToPoint(myRef, NULL, [pt[0] intValue], [pt[1] intValue]);
        
    }
    CGPathAddLineToPoint(myRef, NULL, leftmostX, leftmostY);
    CGContextAddPath(newContextRef, myRef);
    CGContextStrokePath(newContextRef);
    CGPathRelease(myRef);
    
    for(int x = 0; x < mouthImage.size.width; x++) {
        for(int y = 0; y < mouthImage.size.height; y++) {
            if (GET_PIXELMOD2(x, y, 0) || GET_PIXELMOD2(x,y, 1) || GET_PIXELMOD2(x, y, 2)) {
                UIColor *color = [[UIColor alloc] initWithRed:GET_PIXELMOD2(x, y, 0) green:GET_PIXELMOD2(x, y, 1) blue:GET_PIXELMOD2(x, y, 2) alpha:1.0];
                CGContextSetFillColorWithColor(newContextRef, color.CGColor);
                CGContextFillRect(newContextRef, CGRectMake(x-1, y-1, 2, 2));
            }
            
        }
    }
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show MODIFIED  image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    
    
    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);
    
    
    CFRelease(pixelData);
    
    
    free(testimagedata);
    free(testimagedataMod1);
    free(testimagedataMod2);
    free(zeroArray);
    return modifiedImage;
    //return [ocv edgeMeanShiftDetectReturnEdges:mouthImage];*/
    
}
@end
