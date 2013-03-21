//
//  FindMouthsViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/15/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#define TABLEVIEW_CELL_HEIGHT 150

#import "FindMouthsViewController.h"

@interface FindMouthsViewController ()

@end

@implementation FindMouthsViewController

@synthesize tableview;
@synthesize launchMouthsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // data source for tableview
        fileInfos = [NSMutableArray new];
        
        // directory and file IO stuff
        manager = [NSFileManager defaultManager];
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
        
        testDir = [docsDir stringByAppendingPathComponent:@"TEST_DIR"];
        [manager removeItemAtPath:testDir error:NULL];
        if (![manager fileExistsAtPath:testDir]) {
            [manager createDirectoryAtPath:testDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        modelMouthDir = [docsDir stringByAppendingPathComponent:@"MODEL_MOUTHS"];
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    progress = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 400, 280, 30)];
    progress.progress = 0.0;
    [self.view addSubview:progress];
    
    activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(135, 200, 50, 50)];
    activity.hidesWhenStopped = YES;
    activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [activity startAnimating];
    [self.view addSubview:activity];
    
    self.tableview.hidden = YES;
    
    ocv = [OpenCvClass new];
    ocv.delegate = self;
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
    
}


-(void)loadTableView {
@autoreleasepool {
    
    selectedCellRow = -1;
    
    NSArray *fileList;
    fileList = [manager contentsOfDirectoryAtPath:originalDir error:NULL];
    
    
    for (int i=0; i < fileList.count; i++) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = (float)(i+1)/(float)fileList.count;
        });
        
        NSString *fileName = [fileList objectAtIndex:i];
        
        // Process originals for thumbs here
        NSString *fileNamePath = [originalDir stringByAppendingPathComponent:fileName];
        UIImage *origImage = [UIImage imageWithContentsOfFile:fileNamePath];
        if (!origImage) {
            NSLog(@"NOT A VALID IMAGE: %@",fileName);
            continue;
        } else {
            //NSLog(@"%@ - Processing...",fileName);
        }
        CGFloat thumbScaleFactor = 1.0;
        if (origImage.size.height > TABLEVIEW_CELL_HEIGHT) {
            thumbScaleFactor = TABLEVIEW_CELL_HEIGHT / origImage.size.height;
        }
        CGSize scaledDownSize = CGSizeMake(thumbScaleFactor*origImage.size.width, thumbScaleFactor*origImage.size.height);
        UIImage *scaledImage = [self imageWithImage:origImage scaledToSize:scaledDownSize];
        NSData *dataToWrite = UIImagePNGRepresentation(scaledImage);
        NSString *thumbPath = [originalThumbsDir stringByAppendingPathComponent:fileName];
        thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        [dataToWrite writeToFile:thumbPath atomically:YES];
        
        
        // Find Mouths in original images here
        
        // Orient images for face detection (EXIF Orientation = 0)
        NSData *testimageNSData = [NSData dataWithContentsOfFile:fileNamePath];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
        CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
        NSDictionary *metadata = (__bridge NSDictionary *) dictRef;
        int orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        CFRelease(dictRef);
        CFRelease(source);
        
        UIImage *testimage = [UIImage imageWithContentsOfFile:fileNamePath];
        if (orientation==6) {
            // rotate CGImageRef data
            CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0];
            testimage = [UIImage imageWithCGImage:rotatedImageRef];
            CGImageRelease(rotatedImageRef);
        } else if (orientation == 3) {
            CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:M_PI];
            testimage = [UIImage imageWithCGImage:rotatedImageRef];
            CGImageRelease(rotatedImageRef);
        } else if (orientation>1) {
           NSLog(@"%@ Orientation %d not 0, 1 or 6. Need to accommodate here",fileNamePath,orientation);
        }
        
        // Scale down to 1024 max dimension for speed optimization of face detect
        int w = (int)testimage.size.width;
        int h = (int)testimage.size.height;
        int maxDimension = w>h? w : h;
        CGFloat facedetectScaleFactor = 1.0;
        if (maxDimension > 1024) {
            facedetectScaleFactor = 1024.0 / (CGFloat)maxDimension;
        }
        scaledDownSize = CGSizeMake(facedetectScaleFactor*w, facedetectScaleFactor*h);
        scaledImage = [self imageWithImage:testimage scaledToSize:scaledDownSize];

        
        // search for face in scaledImage
        // OpenCV Processing Called Here for Face Detect
        
        
        // testimage - faceRectInScaledOrigImage is set by delegate method call
        testimage = [ocv processUIImageForFace:scaledImage fromFile:fileName];
        if ((faceRectInScaledOrigImage.size.width == 0) || (faceRectInScaledOrigImage.size.height == 0)) {
            NSLog(@"NO FACE in %@",fileName);
            [manager copyItemAtPath:fileNamePath toPath:[NoFaceDir stringByAppendingPathComponent:fileName] error:nil];
            continue;
        }
        
        
        // extract bottom half of face from COLOR image
        CGImageRef cutBottomHalfFaceRef = CGImageCreateWithImageInRect(testimage.CGImage, CGRectMake((int)(faceRectInScaledOrigImage.origin.x), (int)(faceRectInScaledOrigImage.origin.y+0.66*faceRectInScaledOrigImage.size.height), (int)(faceRectInScaledOrigImage.size.width), (int)(0.34*faceRectInScaledOrigImage.size.height)));
        
        
        // locate mouth in bottom half of greyscale face image
        UIImage *bottomhalffaceImage = [UIImage imageWithCGImage:cutBottomHalfFaceRef];
        // do not know why but CGImageCreateWithImageInRect() can not be pixel mapped??
        // bottomhalffaceImage = [ocv greyTheImage:bottomhalffaceImage];

        
        //int mouthIdx = -1;
        CGRect mouthRectInBottomHalfOfFace = CGRectMake(0,0,0,0);
        
        
        // OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
        mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:bottomhalffaceImage fromFile:fileName];
        // BruteForce Processing Called Here - search for mouth in bottom half of greyscale face
        // using MODELMOUTHxxx.png files in /MODEL_MOUTHS/
        //[self processUIImageForMouth:bottomhalffaceImage returnRect:&mouthRectInBottomHalfOfFace closestMouthMatch:&mouthIdx fileName:fileName];
            
        
        if ((mouthRectInBottomHalfOfFace.size.width == 0) || (mouthRectInBottomHalfOfFace.size.height == 0)) {
            NSLog(@"NO MOUTH in %@",fileName);
            [manager copyItemAtPath:fileNamePath toPath:[NoMouthDir stringByAppendingPathComponent:fileName] error:nil];
            continue;
        }
        
        // extract mouth from face
        CGImageRef cutMouthRef = CGImageCreateWithImageInRect(bottomhalffaceImage.CGImage, CGRectMake(mouthRectInBottomHalfOfFace.origin.x, mouthRectInBottomHalfOfFace.origin.y, mouthRectInBottomHalfOfFace.size.width, mouthRectInBottomHalfOfFace.size.height));
        UIImage *mouthImage = [UIImage imageWithCGImage:cutMouthRef];
        CGImageRelease(cutMouthRef);        
        
        UIImage *processedMouthImage = nil;
        if ((faceRectInScaledOrigImage.size.width > 0) && (faceRectInScaledOrigImage.size.height > 0)) {
            processedMouthImage = [ocv edgeDetectReturnOverlay:mouthImage];
        }
        
        // write mouth images to EXTRACTED_MOUTHS directory
        dataToWrite = UIImagePNGRepresentation(mouthImage);
        thumbPath = [extractedMouthsDir stringByAppendingPathComponent:fileName];
        thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        [dataToWrite writeToFile:thumbPath atomically:YES];
        
        //processedMouthImage = [ocv edgeDetectReturnEdges:mouthImage];
        if ((faceRectInScaledOrigImage.size.width > 0) && (faceRectInScaledOrigImage.size.height > 0)) {
            
            //processedMouthImage = [ocv edgeMeanShiftDetectReturnEdges:mouthImage];
            processedMouthImage = [self lookForTeethInMouthImage:mouthImage];
            
            if (!((processedMouthImage.size.width>0) && (processedMouthImage.size.height>0))) {
                NSLog(@"NO TEETH in %@",fileName);
                continue;
            }
        }
        
        // convert to RGB since following code is RGB based
        processedMouthImage = [ocv BGRA2BGRTheImage:processedMouthImage];
        
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
                
                //if (sum > (3*128)) {
                if (1) {
                    memcpy((mutablebuffer4 + i*w*4 + j*4), (mutablebuffer + i*w*3 + j*3), 3);
                } else {
                    bzero((mutablebuffer4 + i*w*4 + j*4), 3);
                }
                
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
        dataToWrite = UIImagePNGRepresentation(modifiedImage);
        thumbPath = [extractedMouthsEdgesDir stringByAppendingPathComponent:fileName];
        thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        [dataToWrite writeToFile:thumbPath atomically:YES];
        
        
        
        NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         fileName,@"originalFileName",
                                         [NSNumber numberWithFloat:thumbScaleFactor],@"thumbScaleFactor",
                                         [NSNumber numberWithFloat:facedetectScaleFactor],@"facedetectScaleFactor",
                                         [NSNumber numberWithFloat:faceRectInScaledOrigImage.origin.x],@"facedetectX",
                                         [NSNumber numberWithFloat:faceRectInScaledOrigImage.origin.y],@"facedetectY",
                                         [NSNumber numberWithFloat:faceRectInScaledOrigImage.size.width],@"facedetectW",
                                         [NSNumber numberWithFloat:faceRectInScaledOrigImage.size.height],@"facedetectH",
                                         [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.origin.x],@"mouthdetectX",
                                         [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.origin.y],@"mouthdetectY",
                                         [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.size.width],@"mouthdetectW",
                                         [NSNumber numberWithFloat:mouthRectInBottomHalfOfFace.size.height],@"mouthdetectH",
                                         nil];
        [fileInfos addObject:fileInfo];
        
        
    }
        
}
    
    // reload tableview with created data model
    usleep(100000);
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
        self.tableview.hidden = NO;
        [activity stopAnimating];
        progress.hidden = YES;
        launchMouthsButton.enabled = YES;
    });
    
}



-(void)setFaceRect:(CGRect)facerectArea {
    faceRectInScaledOrigImage = facerectArea;
}





- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (fileInfos.count > 0) {
        return fileInfos.count;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (fileInfos.count == 0) {
        return 568;
    } else {
        return TABLEVIEW_CELL_HEIGHT;
    }
}


#define RED_RECT_TAG 100
#define BLACK_RECT_TAG 101

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.adjustsFontSizeToFitWidth  = YES;
        
        UIView *blackRectangle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 10)];
        blackRectangle.tag = BLACK_RECT_TAG;
        blackRectangle.backgroundColor = [UIColor blackColor];
        blackRectangle.alpha = 0.5;
        [cell.imageView addSubview:blackRectangle];
        
        UIView *redRectangle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        redRectangle.tag = RED_RECT_TAG;
        redRectangle.backgroundColor = [UIColor redColor];
        redRectangle.alpha = 0.25;
        [cell.imageView addSubview:redRectangle];
    }
    
    if (fileInfos.count == 0) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"No Face Images To Display";
        cell.detailTextLabel.text = nil;
    } else {
        NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];

        cell.imageView.image = [UIImage imageWithContentsOfFile:[originalThumbsDir stringByAppendingPathComponent:[[[fileInfo objectForKey:@"originalFileName"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]]];
        cell.textLabel.text = [fileInfo objectForKey:@"originalFileName"];
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (fileInfos.count==0) {
        return;
    }
    
    selectedCellRow = indexPath.row;
    [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    [self launchMouthsButtonPressed];
    
}




- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (fileInfos.count == 0) {
        return;
    }
    
    
    NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];
    CGFloat thumbScaleFactor = [(NSNumber *)[fileInfo objectForKey:@"thumbScaleFactor"] floatValue];
    CGFloat facedetectScaleFactor = [(NSNumber *)[fileInfo objectForKey:@"facedetectScaleFactor"] floatValue];
    
    // Draw red rectangle around face in thumb image
    
    UIView *redRectangle = [cell.imageView viewWithTag:RED_RECT_TAG];
    CGFloat FaceX = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"facedetectX"] floatValue] / facedetectScaleFactor;
    CGFloat FaceY = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"facedetectY"] floatValue] / facedetectScaleFactor;
    CGFloat FaceW = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"facedetectW"] floatValue] / facedetectScaleFactor;
    CGFloat FaceH = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"facedetectH"] floatValue] / facedetectScaleFactor;
    redRectangle.frame = CGRectMake(FaceX, FaceY, FaceW,FaceH);
    
    
    // Draw black rectangle around mouth area in thumb image
    
    UIView *blackRectangle = [cell.imageView viewWithTag:BLACK_RECT_TAG];
    CGFloat MouthX = FaceX + (thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"mouthdetectX"] floatValue] / facedetectScaleFactor);
    CGFloat MouthY = FaceY + (thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"mouthdetectY"] floatValue] / facedetectScaleFactor) + (thumbScaleFactor * 0.66 *[(NSNumber *)[fileInfo objectForKey:@"facedetectH"] floatValue] / facedetectScaleFactor);
    CGFloat MouthW = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"mouthdetectW"] floatValue] / facedetectScaleFactor;
    CGFloat MouthH = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"mouthdetectH"] floatValue] / facedetectScaleFactor;
    blackRectangle.frame = CGRectMake(MouthX, MouthY, MouthW, MouthH);
    
    // show highlight for selected cell
    if (indexPath.row == selectedCellRow) {
        cell.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.2];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
}



-(IBAction)launchMouthsButtonPressed {
    
    ShowMouthsViewController *smvc = [ShowMouthsViewController new];
    smvc.delegate = self;
    smvc.selectedCellRow = selectedCellRow;
    smvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:smvc animated:YES completion:NULL];
    smvc = nil;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    // OCV exposure compensator
    
	return newImage;
}



- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angleInRadians
{
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(imgRef);
    CGBitmapInfo bitinfo = CGImageGetBitmapInfo(imgRef);
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   bitinfo);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);
    
	return rotatedImage;
}


// delegate method
-(void)setHighlightedCellRow:(int)n {
    selectedCellRow = n;
    [self.tableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedCellRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self.tableview reloadRowsAtIndexPaths:[self.tableview indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)centerOnSelectedCell {
    if (selectedCellRow>=0) {
        [self.tableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedCellRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self.tableview reloadRowsAtIndexPaths:[self.tableview indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
}



#define MODELMOUTH_START_INDEX 1
#define MODELMOUTH_END_INDEX 10

-(void)processUIImageForMouth:(UIImage *)bottomhalffaceImage returnRect:(CGRect *)mouthRectInBottomHalfOfFace closestMouthMatch:(int *)idx fileName:(NSString *)fn {
    
    NSLog(@"Processing: %@",fn);
    
    NSData *dataToWrite1 = UIImagePNGRepresentation(bottomhalffaceImage);
    NSString *thumbPath2 = [testDir stringByAppendingPathComponent:@"temp"];
    thumbPath2 = [[thumbPath2 stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite1 writeToFile:thumbPath2 atomically:YES];
    bottomhalffaceImage = [UIImage imageWithContentsOfFile:thumbPath2];

    
    
    // bottomhalffaceImageBuffer is a bottomhalffaceImageBufferw by bottomhalffaceImageBufferh 2D GreyScale Buffer to search
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(bottomhalffaceImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedata = CFDataGetBytePtr(pixelData);
    int bottomhalffaceImagew = (int)bottomhalffaceImage.size.width;
    int bottomhalffaceImageh = (int)bottomhalffaceImage.size.height;
    uint8_t *bottomhalffaceImageBuffer = (uint8_t *)malloc(bottomhalffaceImagew*bottomhalffaceImageh*4);
    memcpy(bottomhalffaceImageBuffer,testimagedata,bottomhalffaceImagew*bottomhalffaceImageh*4);
    
    
    // show image on iPhone view
    
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(bottomhalffaceImage.CGImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(bottomhalffaceImage.CGImage);
    
    CGContextRef newContextRef = CGBitmapContextCreate(bottomhalffaceImageBuffer, bottomhalffaceImagew, bottomhalffaceImageh, 8, bottomhalffaceImagew*4,colorspaceRef, bitmapInfo);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
    
    // show MODIFIED  image on iPhone screen
    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    CGContextRelease(newContextRef);

    
    
    
    
    CFRelease(pixelData);
    
    
    
    NSData *dataToWrite = UIImagePNGRepresentation(modifiedImage);
    NSString *thumbPath = [testDir stringByAppendingPathComponent:fn];
    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    [dataToWrite writeToFile:thumbPath atomically:YES];
    
    
//    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(bottomhalffaceImage.CGImage);
//    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(bottomhalffaceImage.CGImage);
//    CGContextRef newContextRef = CGBitmapContextCreate(bottomhalffaceImageBuffer, bottomhalffaceImagew, bottomhalffaceImageh, 8, bottomhalffaceImagew*1,colorspaceRef, bitmapInfo);
//    CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
//    UIImage *modifiedImage = [UIImage imageWithCGImage:newImageRef];
//    NSData *dataToWrite = UIImagePNGRepresentation(modifiedImage);
//    NSString *thumbPath = [testDir stringByAppendingPathComponent:fn];
//    thumbPath = [[thumbPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
//    [dataToWrite writeToFile:thumbPath atomically:YES];
//    CGImageRelease(newImageRef);
//    CGContextRelease(newContextRef);
    
    
    
    float minAvgSAD = 3*256.0;
    int minAvgSADn = -1;
    CGFloat minAvgSADx = 0.0;
    CGFloat minAvgSADy = 0.0;
    CGFloat minAvgSADw = 0.0;
    CGFloat minAvgSADh = 0.0;
    
    
    
    for (int N = MODELMOUTH_START_INDEX; N <= MODELMOUTH_END_INDEX; N++) {
        
        
        NSString *mouthFileName = [NSString stringWithFormat:@"modelmouth%03d.png",N];
        NSString *mouthFileNamePath = [modelMouthDir stringByAppendingPathComponent:mouthFileName];
        UIImage *mouthImage = [UIImage imageWithContentsOfFile:mouthFileNamePath];
        if (!mouthImage) {
            NSLog(@"File %@ does not exist",mouthFileName);
            continue;
        }
    
        myDataProvider = CGImageGetDataProvider(mouthImage.CGImage);
        pixelData = CGDataProviderCopyData(myDataProvider);
        testimagedata = CFDataGetBytePtr(pixelData);
        int teethw = (int)mouthImage.size.width;
        int teethh = (int)mouthImage.size.height;
        uint8_t *teethImageBuffer = (uint8_t *)malloc(teethw*teethh*4);
        memcpy(teethImageBuffer,testimagedata,teethw*teethh*4);
        CFRelease(pixelData);
//        
//        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(mouthImage.CGImage);
//        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(mouthImage.CGImage);

        
        
        for (int x=0; x<(bottomhalffaceImagew-teethw); x++) {
            for (int y=0; y<(bottomhalffaceImageh-teethh); y++) {
                
                int pixelCount = 0;
                float sumOfSAD = 0;
                
                int zeroPixelCount = 0;

                
                for (int yy=0; yy<teethh; yy++) {
                    for (int xx=0; xx<teethw; xx++) {
                        
                        
                        if ((*(teethImageBuffer+yy*teethw*4+xx*4+0) + *(teethImageBuffer+yy*teethw*4+xx*4+1) + *(teethImageBuffer+yy*teethw*4+xx*4+2) ) > 0 ) {
                            
                            pixelCount++;
                            
                            
                            float Rmouth = (float)*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 0);
                            float Gmouth = (float)*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 1);
                            float Bmouth = (float)*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 2);
                            float Rteeth = (float)*(teethImageBuffer+yy*teethw*4+xx*4+0);
                            float Gteeth = (float)*(teethImageBuffer+yy*teethw*4+xx*4+1);
                            float Bteeth = (float)*(teethImageBuffer+yy*teethw*4+xx*4+2);
                            
                            float Ymouth = 0.299*Rmouth + 0.587*Gmouth + 0.114*Bmouth;
                            float CRmouth = 0.713*(Rmouth - Ymouth);
                            float CBmouth = 0.564*(Bmouth - Ymouth);
                            float Yteeth = 0.299*Rteeth + 0.587*Gteeth + 0.114*Bteeth;
                            float CRteeth = 0.713*(Rteeth - Yteeth);
                            float CBteeth = 0.564*(Bteeth - Yteeth);
                            

                            if (CRmouth>CRteeth) {
                                sumOfSAD += (CRmouth - CRteeth);
                            } else {
                                sumOfSAD += (CRteeth - CRmouth);
                            }
                            if (CBmouth>CBteeth) {
                                sumOfSAD += (CBmouth - CBteeth);
                            } else {
                                sumOfSAD += (CBteeth - CBmouth);
                            }
                            
                            
//                            // abs() Does not make a difference, but added to be extra safe
//                            
//                            if (*(teethImageBuffer+yy*teethw*4+xx*4+0)  >=  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 0)) {
//                            sumOfSAD += abs(*(teethImageBuffer+yy*teethw*4+xx*4+0)  -  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 0));
//                            } else {
//                                sumOfSAD += abs(*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 0) - *(teethImageBuffer+yy*teethw*4+xx*4+0));
//                            }
//                            
//                            if (*(teethImageBuffer+yy*teethw*4+xx*4+1)  >=  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 1)) {
//                                sumOfSAD += abs(*(teethImageBuffer+yy*teethw*4+xx*4+1)  -  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 1));
//                            } else {
//                                sumOfSAD += abs(*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 1) - *(teethImageBuffer+yy*teethw*4+xx*4+1));
//                            }
//                            
//                            if (*(teethImageBuffer+yy*teethw*4+xx*4+2)  >=  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 2)) {
//                                sumOfSAD += abs(*(teethImageBuffer+yy*teethw*4+xx*4+2)  -  *(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 2));
//                            } else {
//                                sumOfSAD += abs(*(bottomhalffaceImageBuffer + y*bottomhalffaceImagew*4 + x*4 + yy*bottomhalffaceImagew*4 + xx*4 + 2) - *(teethImageBuffer+yy*teethw*4+xx*4+2));
//                            }
                            
                        
                        
                        } else {
                            zeroPixelCount++;
                        }
                    }
                }
            
            
            
            float avgSAD = (float)sumOfSAD / (float)pixelCount;
            
                if (avgSAD < minAvgSAD) {
                    minAvgSAD = avgSAD;
                    minAvgSADn = N;
                    minAvgSADx = (float)x;
                    minAvgSADy = (float)y;
                    minAvgSADw = (float)teethw;
                    minAvgSADh = (float)teethh;
                }

                
            }
        }
        
        
        
        
        
        free(teethImageBuffer);
    }
    
    
    
    // return values:
    *idx = minAvgSADn;
    *mouthRectInBottomHalfOfFace = CGRectMake(minAvgSADx, minAvgSADy, minAvgSADw, minAvgSADh);
    NSLog(@"%@ %d %f",fn,minAvgSADn,minAvgSAD);
    free(bottomhalffaceImageBuffer);
    
}




//=======================================================================================


#define GET_PIXELORIG(X,Y,Z) testimagedataOrig[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXEL(X,Y,Z) testimagedata[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD1(X,Y,Z) testimagedataMod1[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define GET_PIXELMOD2(X,Y,Z) testimagedataMod2[((int)mouthImage.size.width * 4 * Y) + (4 * X) + Z]
#define PIXEL_INDEX(X,Y) Y *(int)mouthImage.size.width + X

// Drew's Algorithm to go here:
-(UIImage *)lookForTeethInMouthImage:(UIImage*)mouthImage {
    
    mouthImage = [ocv edgeDetectReturnEdges:mouthImage];
    //mouthImage = [ocv colorTheImage:mouthImage];
    
    
    CGDataProviderRef myDataProvider = CGImageGetDataProvider(mouthImage.CGImage);
    CFDataRef pixelData = CGDataProviderCopyData(myDataProvider);
    const uint8_t *testimagedataOrig = CFDataGetBytePtr(pixelData);
    
    uint8_t *testimagedata = malloc(mouthImage.size.height * mouthImage.size.width *4);
    uint8_t *testimagedataMod1 = malloc(mouthImage.size.height * mouthImage.size.width *4);
    uint8_t *testimagedataMod2 = malloc(mouthImage.size.height * mouthImage.size.width *4);
    memcpy(testimagedata, testimagedataOrig, mouthImage.size.height * mouthImage.size.width *4);
    bzero(testimagedataMod1, mouthImage.size.height * mouthImage.size.width *4);
    bzero(testimagedataMod2, mouthImage.size.height * mouthImage.size.width *4);
    
    uint8_t *zeroArray = malloc(mouthImage.size.height * mouthImage.size.width);
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
    
    
#define DELTA_ALLOWED_FOR_WHITE 20
#define THRESHOLD_WHITE_BLACK 20
#define MIN_Y_BRIGHTNESS_THRESHOLD 150
#define MAX_CR_THRESHOLD_WHITETEETH 20
#define MAX_CB_THRESHOLD_WHITETEETH 10
#define EXPECT_TEETH 3
#define NUMBER_OF_LINES 10000
#define MIN_TOOTH_SIZE 40 
#define MAX_TOOTH_SIZE 50
#define MIN_DARK_SIZE 1
#define MAX_DARK_SIZE 2 
    
    
    int MouthWidth = mouthImage.size.width;
    int MouthHeight = mouthImage.size.height;
    int cX = MouthWidth / 2;
    
    
    for(int cY = 0; cY < MouthHeight; cY += 5) {
        for(int toothSize = MIN_TOOTH_SIZE; toothSize <= MAX_TOOTH_SIZE; toothSize++) {
            for(int darkSize = MIN_DARK_SIZE; darkSize <= MAX_DARK_SIZE; darkSize++) {
                @autoreleasepool {

                for(int toothShufflePx = 0; toothShufflePx < 50; toothShufflePx++) {
                    
                    //rotate
                    for(float theta = -M_PI_4; theta <= M_PI_4; theta+= 0.1) {
                        BOOL found_teeth = YES;
                        NSMutableArray *line = [[NSMutableArray alloc] init];
                        int prevToothY = -1;
                        for(int toothCount = 0; toothCount < EXPECT_TEETH; toothCount++) {
                            int tooth_notRotated_X = toothCount * (toothSize + darkSize);
                            int tooth_notRotated_Y = 0;
                            int toothCenterX = tooth_notRotated_X + toothShufflePx; //this operates in a [tooth] - [tooth] coordinate system
                            int toothCenterY = tooth_notRotated_Y;
                            int tooth_rotatedX = toothCenterX*cos(theta) - toothCenterY*sin(theta);
                            int tooth_rotatedY = toothCenterX * sin(theta) + toothCenterY * cos(theta) + cY; //which we rotate along some angle, §L95
                            if (tooth_rotatedX >= mouthImage.size.width || tooth_rotatedX < 0) {
                                found_teeth = NO;
                                break;
                            }
                            if (tooth_rotatedY >= mouthImage.size.height || tooth_rotatedY < 0) {
                                found_teeth = NO;
                                break;
                            }
                            
                            int toothY = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 0);
                            if (toothY < MIN_Y_BRIGHTNESS_THRESHOLD) {
                                found_teeth = NO;
                                break;
                            }
                            //we compute the coord of the dark patch
                            int dark_notRotated_X = tooth_notRotated_X + toothSize / 2;
                            int dark_notRotated_Y = tooth_notRotated_Y;
                            dark_notRotated_X += darkSize / 2;
                            int dark_rotatedX = dark_notRotated_X * cos(theta) - dark_notRotated_Y * sin(theta);
                            int dark_rotatedY = dark_notRotated_X * sin(theta) + dark_notRotated_Y * cos(theta) + cY;
                            if (dark_rotatedX >= mouthImage.size.width || dark_rotatedX < 0) {
                                found_teeth = NO;
                                break;
                            }
                            if (dark_rotatedY >= mouthImage.size.height || dark_rotatedY < 0) {
                                found_teeth = NO;
                                break;
                            }
                            int darkY = GET_PIXELMOD1(dark_rotatedX, dark_rotatedY, 0);
                            
                            if (abs(toothY - darkY) < THRESHOLD_WHITE_BLACK) {
                                found_teeth = NO;
                                break;
                            }
                            if (prevToothY != -1 && abs(prevToothY - toothY) > DELTA_ALLOWED_FOR_WHITE) {
                                found_teeth = NO;
                                break;
                            }
                            if (toothY < MIN_Y_BRIGHTNESS_THRESHOLD) {
                             found_teeth = NO;
                             break;
                             }
                            int toothCR = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 1);
                            if (toothCR > MAX_CR_THRESHOLD_WHITETEETH) {
                                found_teeth = NO;
                                break;
                            }
                            int toothCB = GET_PIXELMOD1(tooth_rotatedX, tooth_rotatedY, 2);
                            if (toothCB > MAX_CB_THRESHOLD_WHITETEETH) {
                                found_teeth = NO;
                                break;
                            }
                            
                            
                            
                            NSArray *coord = [[NSArray alloc] initWithObjects:@(tooth_rotatedX),@(tooth_rotatedY),@(0), nil];
                            NSArray *darkCoord = [[NSArray alloc] initWithObjects:@(dark_rotatedX),@(dark_rotatedY),@(2), nil];
                            
                            [line addObject:coord];
                            [line addObject:darkCoord];
                            prevToothY = toothY;
                        }
                        if (found_teeth) {
                            //NSLog(@"found teeth at %@",line);
                            for(NSArray *coord in line) {
                                GET_PIXELMOD2([coord[0] intValue], [coord[1] intValue], [coord[2] intValue]) = 0xff;
                            }
                        }
                        
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
