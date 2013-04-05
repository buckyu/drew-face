//
//  ShowMouthsViewController.h
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/19/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//


@protocol ShowMouthsViewControllerClassDelegate
-(void)setHighlightedCellRow:(int)n;
-(void)centerOnSelectedCell;
@end


#import <UIKit/UIKit.h>
//#import "OpenCvClass.h"

@interface ShowMouthsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    __weak id <ShowMouthsViewControllerClassDelegate> delegate;
    
    NSMutableArray *fileInfos;
    
    NSFileManager *manager;
    NSString *docsDir;
    NSString *extractedMouthsDir;
    NSString *extractedMouthsEdgesDir;
    
    BOOL ShowMouthsBool;
    BOOL ShowEdgesBool;
    
}

@property (weak) id <ShowMouthsViewControllerClassDelegate> delegate;
@property int selectedCellRow;

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleListButton;

-(IBAction)backButtonPressed;
-(IBAction)toggleListButtonPressed;


@end
