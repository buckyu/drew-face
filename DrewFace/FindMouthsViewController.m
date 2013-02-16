//
//  FindMouthsViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/15/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FindMouthsViewController.h"

@interface FindMouthsViewController ()

@end

@implementation FindMouthsViewController

@synthesize tableview;

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
        extractedTeethDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_TEETH"];
        [manager removeItemAtPath:extractedTeethDir error:NULL];
        if (![manager fileExistsAtPath:extractedTeethDir]) {
            [manager createDirectoryAtPath:extractedTeethDir withIntermediateDirectories:YES attributes:nil error:NULL];
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
    
    NSArray *fileList;
    fileList = [manager contentsOfDirectoryAtPath:originalDir error:NULL];
    
    
    for (int i=0; i < fileList.count; i++) {
        
        NSString *fileName = [fileList objectAtIndex:i];
        
        // Process originals for thumbs here
        NSString *fileNamePath = [originalDir stringByAppendingPathComponent:fileName];
        UIImage *origImage = [UIImage imageWithContentsOfFile:fileNamePath];
        CGFloat thumbScaleFactor = 1.0;
        if (origImage.size.height > 100.0) {
            thumbScaleFactor = 100.0 / origImage.size.height;
        }
        CGSize scaledDownSize = CGSizeMake(thumbScaleFactor*origImage.size.width, thumbScaleFactor*origImage.size.height);
        UIImage *scaledImage = [self imageWithImage:origImage scaledToSize:scaledDownSize];
        NSData *dataToWrite = UIImagePNGRepresentation(scaledImage);
        NSString *thumbPath = [originalThumbsDir stringByAppendingPathComponent:fileName];
        [dataToWrite writeToFile:thumbPath atomically:YES];
        
        
        // Find Mouths in original images here
        
        // Orient images for face detection (EXIF Orientation = 0)
        NSData *testimageNSData = [NSData dataWithContentsOfFile:fileNamePath];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)testimageNSData, NULL);
        CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
        NSDictionary *metadata = (__bridge NSDictionary *) dictRef;
        int orientation = [[metadata valueForKey:@"Orientation"] integerValue];
        CFRelease(source);
        CFRelease(dictRef);
        UIImage *testimage = [UIImage imageWithContentsOfFile:fileNamePath];
        if (orientation==6) {
            // rotate CGImageRef data
            CGImageRef rotatedImageRef= [self CGImageRotatedByAngle:testimage.CGImage angle:-M_PI/2.0];
            testimage = [UIImage imageWithCGImage:rotatedImageRef];
            CGImageRelease(rotatedImageRef);
        } else if (orientation>0) {
            NSLog(@"Orientation not 0 or 6. Need to accommodate here");
        }

        
        // Scale down to 640 max dimension for speed optimization of face detect
        int w = (int)testimage.size.width;
        int h = (int)testimage.size.height;
        int maxDimension = w>h? w : h;
        CGFloat facedetectScaleFactor = 1.0;
        if (maxDimension > 640.0) {
            facedetectScaleFactor = 640.0 / maxDimension;
        }
        scaledDownSize = CGSizeMake(facedetectScaleFactor*w, facedetectScaleFactor*h);
        scaledImage = [self imageWithImage:testimage scaledToSize:scaledDownSize];

        
        // search for face in scaledImage
        
        
        
        
        
        
        
        NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         fileName,@"originalFileName",
                                         [NSNumber numberWithFloat:thumbScaleFactor],@"thumbScaleFactor",
                                         [NSNumber numberWithFloat:facedetectScaleFactor],@"facedetectScaleFactor",
                                         nil];
        [fileInfos addObject:fileInfo];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = (float)(i+1)/(float)fileList.count;
        });
        
    }

    // reload tableview with created data model
    usleep(100000);
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
        self.tableview.hidden = NO;
        [activity stopAnimating];
        progress.hidden = YES;
    });
    
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
        return 100;
    }
}


#define BLACK_RECT_TAG 100

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
        [cell.imageView addSubview:blackRectangle];
    }
    
    if (fileInfos.count == 0) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"No Teeth Images To Display";
        cell.detailTextLabel.text = nil;
    } else {
        NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];

        cell.imageView.image = [UIImage imageWithContentsOfFile:[originalThumbsDir stringByAppendingPathComponent:[fileInfo objectForKey:@"originalFileName"]]];
        cell.textLabel.text = [fileInfo objectForKey:@"originalFileName"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%f",[(NSNumber *)[fileInfo objectForKey:@"thumbScaleFactor"] floatValue]];
    }
    
    return cell;
}



- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (fileInfos.count == 0) {
        return;
    }
    
    // Draw black rectangle around mouth area in thumb image
    
    UIView *blackRectangle = [cell.imageView viewWithTag:BLACK_RECT_TAG];
    
    NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];
    CGFloat thumbScaleFactor = [(NSNumber *)[fileInfo objectForKey:@"thumbScaleFactor"] floatValue];
    CGFloat MouthX = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"MouthX"] floatValue];
    CGFloat MouthY = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"MouthY"] floatValue];
    CGFloat MouthW = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"MouthW"] floatValue];
    CGFloat MouthH = thumbScaleFactor * [(NSNumber *)[fileInfo objectForKey:@"MouthH"] floatValue];
    
    blackRectangle.frame = CGRectMake(MouthX, MouthY, MouthW, MouthH);
    
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



@end
