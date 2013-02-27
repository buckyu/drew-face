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

#import "ShowMouthsViewController.h"


@interface FindMouthsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, OpenCvClassDelegate, ShowMouthsViewControllerClassDelegate> {
    
    UIProgressView *progress;
    UIActivityIndicatorView *activity;

    NSFileManager *manager;
    NSString *docsDir;
    NSString *originalDir;
    NSString *originalThumbsDir;
    NSString *extractedMouthsDir;
    NSString *extractedMouthsEdgesDir;

    NSMutableArray *fileInfos;
    CGRect faceRectInScaledOrigImage;
    
    int selectedCellRow;
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *launchMouthsButton;

-(void)setFaceRect:(CGRect)facerectArea;
-(IBAction)launchMouthsButtonPressed;

// delegate method
-(void)setHighlightedCellRow:(int)n;
-(void)centerOnSelectedCell;


@end
