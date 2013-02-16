//
//  FindMouthsViewController.h
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/15/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <ImageIO/ImageIO.h>
#import "OpenCvClass.h"


@interface FindMouthsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, OpenCvClassDelegate> {
    
    UIProgressView *progress;
    UIActivityIndicatorView *activity;

    NSFileManager *manager;
    NSString *docsDir;
    NSString *originalDir;
    NSString *originalThumbsDir;
    NSString *extractedTeethDir;

    NSMutableArray *fileInfos;
    CGRect faceRectInScaledOrigImage;
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;

-(void)setFaceRect:(CGRect)facerectArea;


@end
