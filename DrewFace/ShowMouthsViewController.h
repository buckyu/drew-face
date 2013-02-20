//
//  ShowMouthsViewController.h
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/19/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShowMouthsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableArray *fileInfos;
    
    NSFileManager *manager;
    NSString *docsDir;
    NSString *extractedMouthsDir;
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;

-(IBAction)backButtonPressed;


@end
