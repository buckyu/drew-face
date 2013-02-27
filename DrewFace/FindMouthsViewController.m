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
    
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
    
}

-(void)loadTableView {
@autoreleasepool {
    
    selectedCellRow = -1;
    
    NSArray *fileList;
    fileList = [manager contentsOfDirectoryAtPath:originalDir error:NULL];
    
    
    for (int i=0; i < fileList.count; i++) {
        
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
        OpenCvClass *ocv = [OpenCvClass new];
        ocv.delegate = self;
        // testimage converted to greyscale and faceRectInScaledOrigImage is set by delegate method call
        testimage = [ocv processUIImageForFace:scaledImage fromFile:fileName];
        
        
        // extract bottom half of face from grey image
        CGImageRef cutBottomHalfFaceRef = CGImageCreateWithImageInRect(testimage.CGImage, CGRectMake(faceRectInScaledOrigImage.origin.x, faceRectInScaledOrigImage.origin.y+0.66*faceRectInScaledOrigImage.size.height, faceRectInScaledOrigImage.size.width, 0.34*faceRectInScaledOrigImage.size.height));
        
        
        // locate mouth in bottom half of greyscale face image
        UIImage *bottomhalffaceImage = [UIImage imageWithCGImage:cutBottomHalfFaceRef];
        CGImageRelease(cutBottomHalfFaceRef);
        
        CGRect mouthRectInBottomHalfOfFace = CGRectMake(0,0,0,0);
        if ((faceRectInScaledOrigImage.size.width > 0) && (faceRectInScaledOrigImage.size.height > 0)) {
            // OpenCV Processing Called Here - search for mouth in bottom half of greyscale face
            mouthRectInBottomHalfOfFace = [ocv processUIImageForMouth:bottomhalffaceImage fromFile:fileName];
        } else {
            NSLog(@"NO FACE in %@",fileName);
            continue;
        }
        
        if ((mouthRectInBottomHalfOfFace.size.width == 0) || (mouthRectInBottomHalfOfFace.size.height == 0)) {
            NSLog(@"NO MOUTH in %@",fileName);
            continue;
        }
        
        // extract mouth from greyscale face
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
            processedMouthImage = [ocv edgeMeanShiftDetectReturnEdges:mouthImage];
            if (!((processedMouthImage.size.width>0) && (processedMouthImage.size.height>0))) {
                NSLog(@"NO TEETH in %@",fileName);
                continue;
            }
        }
        

        
        
        
        
        // grey scale images here of mouth area
        // look to see if teeth are brighter
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
                
                if (sum > (3*80)) {
                    memcpy((mutablebuffer4 + i*w*4 + j*4), (mutablebuffer + i*w*3 + j*3), 3);
                } else {
                    bzero((mutablebuffer4 + i*w*4 + j*4), 3);
                }
                
            }
        }
        CFRelease(pixelData);
        
        // show greyscale image on iPhone view
        
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(processedMouthImage.CGImage);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(processedMouthImage.CGImage);
        
        CGContextRef newContextRef = CGBitmapContextCreate(mutablebuffer4, w, h, 8, w*4,colorspaceRef, bitmapInfo);
        
        CGImageRef newImageRef = CGBitmapContextCreateImage(newContextRef);
        
        // show MODIFIED grayscale image on iPhone screen
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
        
    
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = (float)(i+1)/(float)fileList.count;
        });
        
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



@end
